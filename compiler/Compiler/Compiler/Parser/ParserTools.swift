//
//  ParserTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension Parser {

    // @Todo: add append method the same as in Lexer
    // to auto-include the Cursor in the Ast
    
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
        // @Todo: static analysis that all paths return a value
        
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
    
    func expressionToFloat(_ expression: Expression, exprType: Type = .float) -> Expression? {
        if let binop = expression as? BinaryOperator {
            guard let left = expressionToFloat(binop.arguments.0, exprType: exprType),
                let right = expressionToFloat(binop.arguments.1, exprType: exprType)
                else { return nil }
            return BinaryOperator(name: binop.name, exprType: .float, arguments: (left, right),
                startCursor: binop.startCursor, endCursor: binop.endCursor)
        }
        if let unop = expression as? UnaryOperator {
            let type = returnType(ofUnaryOperation: unop.name, arg: exprType)
            guard let arg = expressionToFloat(unop.argument, exprType: type) else { return nil }
            return UnaryOperator(name: unop.name, exprType: type, argument: arg,
                                 startCursor: unop.startCursor, endCursor: unop.endCursor)
        }
        if let int = expression as? IntLiteral {
            return FloatLiteral(intLiteral: int)
        }
        if let float = expression as? FloatLiteral {
            return float
        }
        return nil
    }
    
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
    
    func appendDeclaration(_ declaration: Declaration, to scope: Scope) {
        scope.declarations[declaration.name] = declaration
    }
    
    /// returns the error set at the current point
    func error<T>(_ error: String, procedure: String = #function, line: Int = #line,
                  _ start: Cursor? = nil, _ end: Cursor? = nil) -> Result<T, ParserError> {
        let startC = start ?? lastToken.endCursor.advancingCharacter()
        let endC = end ?? startC
        let context = "Error in: \(procedure) #\(line)"
        let error = ParserError(fileName: fileName, startCursor: startC, endCursor: endC,
                                message: error, context: context)
        return .failure(error)
    }
    
    /// advances the counter
    func advance(_ count: Int = 1) {
        i += count
    }
    
    /// advances the counter and sets `token` to the next in the array
    func nextToken() -> Bool {
        guard tokens.count > i+1 else { return false }
        advance()
        token = tokens[i]
        return true
    }
    
    var lastToken: Token {
        if i == 0 { report("Do not call this at the first token") }
        return tokens[i-1]
    }
    
    /// Peeks at the `next` token
    func peekNext(index: Int = 1) -> Token? {
        let nextIndex = i + index
        guard tokens.count > nextIndex else { return nil }
        return tokens[nextIndex]
    }
    
    /// checks if `next token's value` is of the type passed, then eats if if it does
    /// if not, does nothing and returns nil
    func consume<T: TokenValue>(_ value: T.Type) -> (token: Token, value: T)? {
        if let value = token.value as? T {
            defer { nextToken() }
            return (token: token, value: value)
        }
        return nil
    }
    
    /// checks if `next token` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consume(where compare: (TokenValue)->Bool) -> Token? {
        if (compare(token.value)) {
            defer { nextToken() }
            return token
        }
        return nil
    }
    
    /// checks if `next token` exists, is a string-value token, and matches the passed value, then eats it if it does
    /// if not, does nothing and returns `false`
    func consume<T: StringValueToken>(_ type: T.Type, matching value: String) -> Bool {
        consume(where: { ($0 as? T)?.value == value }) != nil
    }
    
    func consumeKeyword(_ keyword: Keyword) -> Bool {
        consume(where: { ($0 as? Keyword) == keyword }) != nil
    }
    
    func consumePunct(_ value: String) -> Bool {
        consume(Punctuator.self, matching: value)
    }
    
    func consumeSep(_ value: String) -> Bool {
        consume(Separator.self, matching: value)
    }

    func consumeOp(_ value: String) -> Bool {
        consume(Operator.self, matching: value)
    }
    
    func consumeOperator() -> (token: Token, value: Operator)? {
         consume(Operator.self)
    }
    
    func consumeIdent() -> (token: Token, value: Identifier)? {
        consume(Identifier.self)
    }
}
