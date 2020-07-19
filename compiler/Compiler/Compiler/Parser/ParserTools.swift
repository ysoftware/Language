//
//  ParserTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func solidId(forName name: String, solidTypes: [Type]) -> String {
    let solidTypesString = solidTypes.map {
        if let genericType = $0 as? StructureType, genericType.isGeneric {
            return solidId(forName: genericType.name, solidTypes: genericType.solidTypes)
        }
        return $0.typeName
    }.joined(separator: "_").replacingOccurrences(of: "*", with: "ptr")
    return "\(name)_\(solidTypesString)"
}

extension Parser {

    func solidifyType(_ type: Type, genericTypes: [String], solidTypes: [Type]) -> Type {
        return type.updateSubtypes { child in
            if let alias = child as? AliasType {
                guard let index = genericTypes.firstIndex(of: alias.name) else {
                    report("Generic type name not found in a struct declaration of type '\(type.typeName)'.\nLooking for alias '\(alias.name)' in generic types: [\(genericTypes.joined(separator: ", "))]\nSolidTypes supplied: [\(solidTypes.map(\.typeName).joined(separator: ", "))]\n", token.range)
                }
                return solidTypes[index]
            }
            return child
        }
    }

    func solidifyAst(_ ast: Ast?, genericTypes: [String], solidTypes: [Type]) {
        guard let ast = ast else { return }
        func recurse(_ ast: Ast?) { solidifyAst(ast, genericTypes: genericTypes, solidTypes: solidTypes) }

        if let varDecl = ast as? VariableDeclaration {
            varDecl.exprType = solidifyType(varDecl.exprType, genericTypes: genericTypes, solidTypes: solidTypes)
            recurse(varDecl.expression)
        } else if let assign = ast as? Assignment {
            recurse(assign.receiver)
            recurse(assign.expression)
        } else if let access = ast as? MemberAccess {
            let structType = access.base.exprType.getValueType() as! StructureType
            recurse(access.base)
            access.exprType = typeResolvingAliases(from: access.exprType, declName: structType.name,
                                                   genericTypes: genericTypes,
                                                   solidTypes: solidTypes + structType.solidTypes)
        } else if let new = ast as? New {
            new.type = solidifyType(new.type, genericTypes: genericTypes, solidTypes: solidTypes)
        } else if let free = ast as? Free {
            recurse(free.expression)
        } else if let binop = ast as? BinaryOperator {
            recurse(binop.arguments.0)
            recurse(binop.arguments.1)
        } else if let unop = ast as? UnaryOperator {
            recurse(unop.argument)
        } else if let ret = ast as? Return {
            recurse(ret.value)
        } else if let wl = ast as? WhileLoop {
            recurse(wl.block)
            recurse(wl.condition)
        } else if let cond = ast as? Condition {
            recurse(cond.condition)
            recurse(cond.block)
            recurse(cond.elseBlock)
        } else if let code = ast as? Code {
            code.statements.forEach(recurse)
        } else if let call = ast as? ProcedureCall {
            call.arguments.forEach(recurse)
        }

        // also generally solidify the type of expression
        if let expr = ast as? Expression {
            expr.exprType = solidifyType(expr.exprType, genericTypes: genericTypes, solidTypes: solidTypes)
        }
    }

    func solidifyProcedure(_ genericProcedure: ProcedureDeclaration, genericTypes: [String], solidTypes: [Type]) {
        let procId = solidId(forName: genericProcedure.name, solidTypes: solidTypes) + "__solidified"
        guard procedureDeclarations[procId] == nil else { return }

        // arguments
        let arguments = genericProcedure.arguments.makeCopy()
        arguments.forEach { $0.exprType = solidifyType($0.exprType, genericTypes: genericTypes, solidTypes: solidTypes) }

        // return type
        let returnType = solidifyType(genericProcedure.returnType, genericTypes: genericTypes, solidTypes: solidTypes)

        // stataments
        let scope = genericProcedure.scope.makeCopy()
        scope.statements.forEach {
            solidifyAst($0, genericTypes: genericTypes, solidTypes: solidTypes)
        }

        let proc = ProcedureDeclaration(id: procId, name: genericProcedure.name,
                                        arguments: arguments, returnType: returnType,
                                        flags: genericProcedure.flags, scope: scope, ood: order())
        procedureDeclarations[procId] = proc
        globalScope.declarations[procId] = proc
    }

    func solidifyStructure(type: StructureType) throws {
        // @Todo: what if we're using generic struct that's undeclared yet?
        // maybe remember that we used it so it will be generated at the time of parsing the declaration?
        let noPointerIdent = type.name // @Todo: this is weird, check this
        if let (genericDecl, genericTypes) = genericDeclarations[noPointerIdent] {
            guard let genericStruct = genericDecl as? StructDeclaration else {
                throw error(ParserMessage.genericNotStructType(genericDecl), genericDecl.range)
            }
            try solidifyStructure(genericStruct, genericTypes: genericTypes, solidTypes: type.solidTypes)
        }
    }

    func solidifyStructure(_ genericStruct: StructDeclaration, genericTypes: [String], solidTypes: [Type]) throws {
        guard !solidTypes.map(\.isAlias).contains(true) else { return }

        let structId = solidId(forName: genericStruct.name, solidTypes: solidTypes) + "__solidified"
        guard structureDeclarations[structId] == nil else { return }

        let solidMembers: [VariableDeclaration] = genericStruct.members.makeCopy().map {
            solidifyAst($0, genericTypes: genericTypes, solidTypes: solidTypes); return $0
        }
        let structure = StructDeclaration(name: genericStruct.name, id: structId, members: solidMembers, ood: order())
        structureDeclarations[structId] = structure
        globalScope.declarations[structId] = structure

        try structure.members.forEach { member in
            if let structType = member.exprType.getValueType() as? StructureType, !structType.solidTypes.contains(where: \.isAlias) {
                try solidifyStructure(structure, genericTypes: genericTypes, solidTypes: solidTypes)
            }
        }

        try solidTypes.forEach { type in
            if let structType = type as? StructureType, structType.isGeneric {
                try solidifyStructure(type: structType)
            }
        }
    }

    func typeResolvingAliases(from type: Type, declName: String, genericTypes: [String], solidTypes: [Type]) -> Type {
        guard type.isAlias else { return type }
        guard let (_, declGenericTypes) = genericDeclarations[declName] else {
            // @Todo: this is also the case for type of a non-generic struct
            // maybe we should traverse the type to see if it contains any Aliastypes and depend on it
            return type
        }
        return typeResolvingAliases(from: type, genericTypes: genericTypes + declGenericTypes, solidTypes: solidTypes)
    }

    func typeResolvingAliases(from type: Type, genericTypes: [String], solidTypes: [Type]) -> Type {
        guard genericTypes.count == solidTypes.count else {
            report("Got generic types: [\(genericTypes.joined(separator: ", "))] but solidTypes: [\(solidTypes.map(\.typeName).joined(separator: ", "))]")
        }

        if var ptr = type as? PointerType {
            ptr.pointeeType = typeResolvingAliases(from: ptr.pointeeType,
                                                   genericTypes: genericTypes, solidTypes: solidTypes)
            return ptr
        }
        if var structure = type as? StructureType {
            for i in 0..<structure.solidTypes.count {

                structure.solidTypes[i] = typeResolvingAliases(from: structure.solidTypes[i],
                                                               declName: structure.name,
                                                               genericTypes: genericTypes,
                                                               solidTypes: solidTypes + structure.solidTypes)
            }
            return structure
        }
        if let alias = type as? AliasType {
            let index: Int
            guard let genericTypeIndex = genericTypes.firstIndex(of: alias.name) else {
                report("Generic type name not found in a struct declaration of type '\(type.typeName)'.\nLooking for alias '\(alias.name)' in generic types: [\(genericTypes.joined(separator: ", "))]\nSolidTypes supplied: [\(solidTypes.map(\.typeName).joined(separator: ", "))]\n", token.range)
            }
            index = genericTypeIndex

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

        if let decl = globalScope.declarations[structType.name] as? StructDeclaration {
            guard let index = decl.members.firstIndex(where: { $0.name == name }) else {
                throw error(ParserMessage.memberAccessUndeclaredMember(name, decl.name), memberRange)
            }

            return (decl.members[index].exprType, index)
        }
        else if let (decl, genericTypes) = genericDeclarations[structType.name] {
            guard structType.solidTypes.count == genericTypes.count else {
                throw error(ParserMessage.temp)
            }

            guard let decl = decl as? StructDeclaration else {
                throw error(ParserMessage.memberAccessNonStruct(baseType), base.range) // @Todo: check if this is correct
            }
            guard let index = decl.members.firstIndex(where: { $0.name == name }) else {
                throw error(ParserMessage.memberAccessUndeclaredMember(name, decl.name), memberRange)
            }

            // @Todo: check for typealiases in local scope

            let solidifiedType = typeResolvingAliases(from: decl.members[index].exprType,
                                                      genericTypes: genericTypes,
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
        if let d = globalScope.declarations[declaration.name]
            ?? scope?.declarations[declaration.name]
            ?? genericDeclarations[declaration.name]?.0 {

            throw error(ParserMessage.declarationConflict(d), d.range)
        }
        return
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

    @inline(__always)
    func order() -> Int {
        defer { ood += 1 }
        return ood
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
