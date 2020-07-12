//
//  ParserTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension Parser {

    func typeResolvingAliases(from type: Type, in scope: Scope, declName: String, solidTypes: [Type]) -> Type {
        guard let decl = scope.declarations[declName] else {
            // @Todo: consider correctly adding a dependency on a yet-undeclared struct
            return UnresolvedType()
        }
        return typeResolvingAliases(from: type, decl: decl, solidTypes: solidTypes)
    }

    func typeResolvingAliases(from type: Type, decl: Declaration, solidTypes: [Type]) -> Type {
        if var ptr = type as? PointerType {
            ptr.pointeeType = typeResolvingAliases(from: ptr.pointeeType,
                                                   decl: decl, solidTypes: solidTypes)
            return ptr
        }
        if var structure = type as? StructureType {
            for i in 0..<structure.solidTypes.count {
                structure.solidTypes[i] = typeResolvingAliases(from: structure.solidTypes[i],
                                                               decl: decl, solidTypes: solidTypes)
            }
            return structure
        }
        if let alias = type as? AliasType {
            let index: Int
            if let decl = decl as? StructDeclaration {
                guard let genericTypeIndex = decl.genericTypes.firstIndex(of: alias.name) else {
                    report("generic type name not found in a struct declaration?")
                }
                index = genericTypeIndex
            }
            else if let decl = decl as? ProcedureDeclaration {
                guard let genericTypeIndex = decl.genericTypes.firstIndex(of: alias.name) else {
                    report("generic type name not found in a struct declaration?")
                }
                index = genericTypeIndex
            }
            else { report("Weird declaration.") }

            let solidType = solidTypes[index]
            return solidType
        }
        return type
    }

    func nextScope(from: Scope, as context: Context? = nil) -> Scope {
        let newScope = Scope(declarations: from.declarations, id: "l\(scopeCounter)_", contexts: from.contexts)
        scopeCounter += 1
        context.map { newScope.contexts.append($0) }
        return newScope
    }

    /// make sure to add dependency for an ast with unresolved type
    func resolveMemberTypeAndIndex(forName name: String, of base: Expression,
                                   in scope: Scope, memberRange: CursorRange) throws -> (type: Type, index: Int?) {
        guard !base.exprType.equals(to: UnresolvedType()) else { return (UnresolvedType(), nil) }

        let baseType = base.exprType.getValueType()
        guard let structType = baseType as? StructureType else {
            throw error(ParserMessage.memberAccessNonStruct(baseType), base.range)
        }

        // @Todo: consider correctly adding a dependency on a yet-undeclared struct

        // @Todo: check if searching in the right way
        let foundDecl = globalScope.declarations[structType.name] ?? scope.declarations[structType.name]

        if let decl = foundDecl as? StructDeclaration {
            guard let index = decl.members.firstIndex(where: { $0.name == name }) else {
                throw error(ParserMessage.memberAccessUndeclaredMember(name, decl.name), memberRange)
            }

            // @Todo: check for typealiases in local scope

            let solidifiedType = typeResolvingAliases(from: decl.members[index].exprType,
                                                      in: scope,
                                                      declName: structType.name,
                                                      solidTypes: structType.solidTypes)
            return (solidifiedType, index)
        }

        return (UnresolvedType(), nil)
    }

    func resolveVarDecl(named name: String, in scope: Scope) -> VariableDeclaration? {
        return (scope.declarations[name] ?? globalScope.declarations[name]) as? VariableDeclaration
    }

    /// nil if error
    func resolveType(named name: String) -> Type? {
        let type = typeNamed(name)
        if type is StructureType {
            guard let decl = globalScope.declarations[name] else {
                return UnresolvedType()
            }
            if let structure = decl as? StructDeclaration {
                return StructureType(name: structure.name)
            }
            return nil
        }
        return type
    }
    
    /// make sure to add dependency for an ast with unresolved type
    func resolveType(of expression: Expression) -> Type {
        let name = expression.exprType.typeName
        let type = typeNamed(name)
        if type is StructureType {
            guard let decl = globalScope.declarations[name] else {
                return UnresolvedType()
            }
            if let structure = decl as? StructDeclaration {
                return StructureType(name: structure.name)
            }
            else if let proc = decl as? ProcedureDeclaration {
                return proc.returnType
            }
            else if let variable = decl as? VariableDeclaration {
                return variable.exprType
            }
        }
        return type
    }
    
    func firstNotMatchingReturnStatement(in code: Code, to returnType: Type) -> Return? {    
        for stat in code.statements {
            if let returnStat = stat as? Return {
                if !returnStat.value.exprType.equals(to: returnType) {
                    return returnStat
                }
            }
            else if let ifStat = stat as? Condition {
                if let r = firstNotMatchingReturnStatement(in: ifStat.block, to: returnType) {
                    return r
                }
                if let r = firstNotMatchingReturnStatement(in: ifStat.elseBlock, to: returnType) {
                    return r
                }
            }
            else if let loop = stat as? WhileLoop {
                if let r = firstNotMatchingReturnStatement(in: loop.block, to: returnType) {
                    return r
                }
            }
        }
        return nil
    }
    
    func convertExpression(_ expression: Expression, to exprType: Type) throws -> Expression? {
        guard !expression.exprType.equals(to: exprType) else { return expression }
        if let binop = expression as? BinaryOperator {
            guard let left = try convertExpression(binop.arguments.0, to: exprType),
                let right = try convertExpression(binop.arguments.1, to: exprType)
                else { return nil }
            return BinaryOperator(name: binop.name, exprType: exprType, arguments: (left, right), range: binop.range)
        }
        if let unop = expression as? UnaryOperator {
            let type = try returnType(ofUnaryOperation: unop.name, arg: exprType)
            guard let arg = try convertExpression(unop.argument, to: type) else { return nil }
            return UnaryOperator(name: unop.name, exprType: type, argument: arg, range: unop.range)
        }
        if let sizeof = expression as? SizeOf {
            guard let int = exprType as? IntType, int.size >= 16 else { return nil }
            return SizeOf(type: sizeof.type, exprType: exprType, range: sizeof.range)
        }
        if expression is NullLiteral {
            guard exprType is PointerType else { return nil }
            return NullLiteral(exprType: exprType, range: expression.range)
        }
        if let int = expression as? IntLiteral {
            guard int.isConvertible(to: exprType) else { return nil }
            if exprType is IntType {
                return IntLiteral(value: int.value, exprType: exprType, range: expression.range)
            }
            else {
                return FloatLiteral(value: Float64(int.value), exprType: exprType, range: expression.range)
            }
        }
        if let float = expression as? FloatLiteral {
            guard float.isConvertible(to: exprType) else { return nil }
            return FloatLiteral(value: Float64(float.value), exprType: exprType, range: expression.range)
        }
        return nil
    }
    
    @inline(__always)
    func appendUnresolved(_ dependency: String, _ statement: Ast) {
        if unresolved[dependency] == nil { unresolved[dependency] = [] }
        unresolved[dependency]!.append(statement)
    }
    
    func verifyNameConflict(_ declaration: Declaration, in scope: Scope? = nil) throws {
        if let d = globalScope.declarations[declaration.name] ?? scope?.declarations[declaration.name] {
            throw error(ParserMessage.declarationConflict(d), d.range)
        }
        return
    }
    
    @inline(__always)
    func appendDeclaration(_ declaration: Declaration, to scope: Scope) {
        scope.declarations[declaration.name] = declaration
    }

    func error(_ e: String, procedure: String = #function, line: Int = #line,
               _ range: CursorRange?) -> ParserError {
        error(e, procedure: procedure, line: line, range?.start, range?.end)
    }

    /// returns the error set at the current point
    func error(_ e: String, procedure: String = #function, line: Int = #line,
               _ start: Cursor? = nil, _ end: Cursor? = nil) -> ParserError {
        let startC = start ?? lastToken.endCursor.advancingCharacter()
        let endC = end ?? startC
        let context = "Error in: \(procedure) #\(line)"
        let error = ParserError(fileName: fileName, startCursor: startC, endCursor: endC,
                                message: e, context: context)
        return error
    }

    func returnType(ofBinaryOperation operation: String, arg: Type) -> Type {
        switch operation {
        // math
        case "*", "/", "%":   return arg
        case "+", "-":        return arg
        case "<<", ">>":      return arg
        // equality
        case "<", ">":        return bool
        case "<=", ">=":      return bool
        case "==", "!=":      return bool
        // boolean
        case "&":             return arg
        case "^":             return arg
        case "|":             return arg
        case "&&":            return bool
        case "||":            return bool

        default: report("Binary operation \(operation) is not yet implemented.")
        }
    }

    func returnType(ofUnaryOperation operation: String, arg: Type) throws -> Type {
        switch operation {
        case UnaryOperator.negation:
            return arg

        case UnaryOperator.dereference:
            guard let ptr = arg as? PointerType else { throw error(ParserMessage.valueNotPointer(arg)) }
            return ptr.pointeeType

        case UnaryOperator.memoryAddress:
            return PointerType(pointeeType: arg)

        case UnaryOperator.cast:
            return any

        default:
            throw error(ParserMessage.notImplemented(token), token.range)
        }
    }

    /// advances the counter
    @inline(__always)
    func advance(_ count: Int = 1) {
        i += count
    }
    
    /// advances the counter and sets `token` to the next in the array
    @inline(__always)
    func nextToken() -> Bool {
        guard tokens.count > i+1 else { return false }
        advance()
        token = tokens[i]
        return true
    }
    
    @inline(__always)
    var lastToken: Token {
        if i == 0 { return tokens[0] }
        return tokens[i-1]
    }
    
    /// Peeks at the `next` token
    @inline(__always)
    func peekNext(index: Int = 1) -> Token? {
        let nextIndex = i + index
        guard tokens.count > nextIndex else { return nil }
        return tokens[nextIndex]
    }
    
    /// checks if `next token's value` is of the type passed, then eats if if it does
    /// if not, does nothing and returns nil
    func consume<T: TokenValue>(_ value: T.Type) -> (token: Token, value: T)? {
        if let value = token.value as? T {
            defer { _ = nextToken() }
            return (token: token, value: value)
        }
        return nil
    }
    
    /// checks if `next token` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consume(where compare: (TokenValue)->Bool) -> Token? {
        if (compare(token.value)) {
            defer { _ = nextToken() }
            return token
        }
        return nil
    }
    
    /// checks if `next token` exists, is a string-value token, and matches the passed value, then eats it if it does
    /// if not, does nothing and returns `false`
    @inline(__always)
    func consume<T: StringValueToken>(_ type: T.Type, matching value: String) -> Bool {
        consume(where: { ($0 as? T)?.value == value }) != nil
    }
    
    @inline(__always)
    func consumeKeyword(_ keyword: Keyword) -> Bool {
        consume(where: { ($0 as? Keyword) == keyword }) != nil
    }
    
    @inline(__always)
    func consumePunct(_ value: String) -> Bool {
        consume(Punctuator.self, matching: value)
    }
    
    @inline(__always)
    func consumeSep(_ value: String) -> Bool {
        consume(Separator.self, matching: value)
    }

    @inline(__always)
    func consumeOp(_ value: String) -> Bool {
        consume(Operator.self, matching: value)
    }
    
    @inline(__always)
    func consumeOperator() -> (token: Token, value: Operator)? {
         consume(Operator.self)
    }
    
    @inline(__always)
    func consumeIdent() -> (token: Token, value: Identifier)? {
        consume(Identifier.self)
    }
}
