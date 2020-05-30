//
//  ParserTools.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension Parser {

    // @Todo: add append method the same as in Lexer
    // to auto-include the Cursor in the Ast
    
    func dependOnGlobal(_ dependency: String, _ statement: Ast) {
        if unresolved[dependency] == nil { unresolved[dependency] = [] }
        unresolved[dependency]!.append(statement)
    }
    
    func verifyNameConflict(_ declaration: Declaration, in scope: Scope? = nil) -> ParserError.Message? {
        if let _ = globalScope.declarations[declaration.name] { return .declarationConflict }
        if let _ = scope?.declarations[declaration.name] { return .declarationConflict }
        // @Todo: improve error message
        return nil
    }
    
    func appendDeclaration(_ declaration: Declaration, to scope: Scope? = nil) {
        (scope ?? globalScope).declarations[declaration.name] = declaration
    }
    
    /// returns the error set at the current point
    func error<T>(_ error: ParserError.Message) -> Result<T, ParserError> {
        .failure(ParserError(fileName: fileName, startCursor: startCursor,
                             endCursor: endCursor, error))
    }
    
    /// advances the counter
    func advance(_ count: Int = 1) {
        i += count
    }
    
    /// advances the counter and sets `token` to the next in the array
    @discardableResult
    func nextToken() -> Bool {
        guard tokens.count > i+1 else { return false }
        advance()
        token = tokens[i]
        return true
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
        return consume(where: { ($0 as? T)?.value == value }) != nil
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
    
    func consumeIdent() -> (token: Token, value: Identifier)? {
        consume(Identifier.self)
    }
}
