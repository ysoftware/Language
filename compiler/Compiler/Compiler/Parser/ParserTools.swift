//
//  ParserTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension Parser {

    /// make sure to add dependency for an ast with unresolved type
    func resolveMemberTypeAndIndex(name: String, of base: Expression) -> (type: Type, index: Int)? {
        guard !base.exprType.equals(to: .unresolved) else { return nil }
        
        var baseType = base.exprType
        if let pointer = base.exprType as? PointerType { baseType = pointer.pointeeType }
        guard let structType = baseType as? StructureType else {
            report("Don't call this resolveMemberType for non-struct bases.")
        }
        
        guard let decl = globalScope.declarations[structType.name] as? StructDeclaration else {
            return nil
        }
        guard let index = decl.members.firstIndex(where: { $0.name == name }) else {
            return nil
        }
        return (decl.members[index].exprType, index)
    }
    
    /// make sure to add dependency for an ast with unresolved type
    func resolveType(_ name: String) -> Type {
        let type = Type.named(name)
        if type is StructureType {
            guard let decl = globalScope.declarations[name] else {
                return .unresolved
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
    
    func convertExpression(_ expression: Expression, to exprType: Type) -> Expression? {
        if let binop = expression as? BinaryOperator {
            guard let left = convertExpression(binop.arguments.0, to: exprType),
                let right = convertExpression(binop.arguments.1, to: exprType)
                else { return nil }
            return BinaryOperator(name: binop.name, exprType: exprType, arguments: (left, right),
                startCursor: binop.startCursor, endCursor: binop.endCursor)
        }
        if let unop = expression as? UnaryOperator {
            let type = returnType(ofUnaryOperation: unop.name, arg: exprType)
            guard let arg = convertExpression(unop.argument, to: type) else { return nil }
            return UnaryOperator(name: unop.name, exprType: type, argument: arg,
                                 startCursor: unop.startCursor, endCursor: unop.endCursor)
        }
        if expression is NullLiteral {
            guard exprType is PointerType else { return nil }
            return NullLiteral(exprType: exprType,
                               startCursor: expression.startCursor, endCursor: expression.endCursor)
        }
        if let int = expression as? IntLiteral {
            guard int.isConvertible(to: exprType) else { return nil }
            if exprType is IntType {
                return IntLiteral(value: int.value, exprType: exprType,
                                  startCursor: expression.startCursor, endCursor: expression.endCursor)
            }
            else {
                return FloatLiteral(value: Float64(int.value), exprType: exprType,
                                    startCursor: expression.startCursor, endCursor: expression.endCursor)
            }
        }
        if let float = expression as? FloatLiteral {
            guard float.isConvertible(to: exprType) else { return nil }
            return FloatLiteral(value: Float64(float.value), exprType: exprType,
                                startCursor: expression.startCursor, endCursor: expression.endCursor)
        }
        return nil
    }
    
    @inline(__always)
    func appendUnresolved(_ dependency: String, _ statement: Ast) {
        if unresolved[dependency] == nil { unresolved[dependency] = [] }
        unresolved[dependency]!.append(statement)
    }
    
    func verifyNameConflict(_ declaration: Declaration, in scope: Scope? = nil) -> String? {
        if let d = globalScope.declarations[declaration.name] { return em.declarationConflict(d) }
        if let d = scope?.declarations[declaration.name] { return em.declarationConflict(d) }
        // @Todo: improve error message
        return nil
    }
    
    @inline(__always)
    func appendDeclaration(_ declaration: Declaration, to scope: Scope) {
        scope.declarations[declaration.name] = declaration
    }
    
    /// returns the error set at the current point
    func error(_ error: String, procedure: String = #function, line: Int = #line,
               _ start: Cursor? = nil, _ end: Cursor? = nil) -> ParserError {
        let startC = start ?? lastToken.endCursor.advancingCharacter()
        let endC = end ?? startC
        let context = "Error in: \(procedure) #\(line)"
        let error = ParserError(fileName: fileName, startCursor: startC, endCursor: endC,
                                message: error, context: context)
        return error
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
