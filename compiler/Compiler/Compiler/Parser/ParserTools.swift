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
    func error<T>(_ error: String, _ start: Cursor, _ end: Cursor? = nil) -> Result<T, ParserError> {
        let endC = end ?? start
        return .failure(ParserError(fileName: fileName, startCursor: start, endCursor: endC, error))
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