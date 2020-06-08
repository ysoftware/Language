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
    
    func expressionToFloat(_ expression: Expression, exprType: Type = .float) -> Expression? {
        if let binop = expression as? BinaryOperator {
            guard let left = expressionToFloat(binop.arguments.0, exprType: exprType),
                let right = expressionToFloat(binop.arguments.1, exprType: exprType)
                else { return nil }
            return BinaryOperator(name: binop.name, exprType: .float, arguments: (left, right))
        }
        if let unop = expression as? UnaryOperator {
            guard let arg = expressionToFloat(unop.argument, exprType: exprType) else { return nil }
            return UnaryOperator(name: unop.name, exprType: .float, argument: arg)
        }
        if let int = expression as? IntLiteral {
            return FloatLiteral(value: Float32(int.value))
        }
        if let float = expression as? FloatLiteral {
            return float
        }
        return nil
    }
    
    func makeBinaryOperation(_ name: String, left: Expression, right: Expression, _ token: Token) -> BinaryOperator {
        let exprType = returnType(of: name, arg: left.exprType)
        let op = BinaryOperator(name: name, exprType: exprType, arguments: (left, right))
        op.startCursor = left.startCursor
        op.endCursor = token.endCursor
        return op
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
        print("Error occured in: \(procedure) #\(line)")
        let startC = start ?? lastToken.endCursor.advancingCharacter()
        let endC = end ?? startC
        return .failure(ParserError(fileName: fileName, startCursor: startC, endCursor: endC, error))
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
        if i == 0 { fatalError("Do not call this at the first token") }
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
