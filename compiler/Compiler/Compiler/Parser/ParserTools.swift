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
    
    func verifyNameConflict(_ declaration: Declaration) -> ParserError.Message? {
        if let _ = global_declarations[declaration.name] {
            // @Todo: improve error message
            return .declarationConflict
        }
        return nil
    }
    
    func dependOnGlobal(_ dependency: String, _ statement: Ast) {
        if unresolved[dependency] == nil { unresolved[dependency] = [] }
        unresolved[dependency]!.append(statement)
    }
    
    func declareGlobal(_ declaration: Declaration) {
        global_declarations[declaration.name] = declaration
    }
    
    /// returns the error set at the current point
    func error<T>(_ error: ParserError.Message) -> Result<T, ParserError> {
        .failure(ParserError(fileName: fileName, cursor: token.endCursor, error))
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
    func consumeNext<T: TokenValue>(_ value: T.Type) -> (token: Token, value: T)? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        let nextToken = tokens[nextIndex]
        if let value = nextToken.value as? T {
            token = nextToken
            advance()
            return (token, value)
        }
        return nil
    }
    
    /// checks if `next token` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consumeNext(where compare: (TokenValue)->Bool) -> Token? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        let nextToken = tokens[nextIndex]
        if compare(nextToken.value) {
            token = nextToken
            advance()
            return token
        }
        return nil
    }
    
    /// checks if `next token` exists, is a string-value token, and matches the passed value, then eats it if it does
    /// if not, does nothing and returns `false`
    func consumeNext<T: StringValueToken>(_ type: T.Type, matching value: String) -> Bool {
        return consumeNext(where: { ($0 as? T)?.value == value }) != nil
    }
    
    func consumeKeyword(_ keyword: Keyword) -> Bool {
        consumeNext(where: { ($0 as? Keyword) == .else }) != nil
    }
    
    func consumePunct(_ value: String) -> Bool {
        consumeNext(Punctuator.self, matching: value)
    }
    
    func consumeSep(_ value: String) -> Bool {
        consumeNext(Separator.self, matching: value)
    }
    
    func consumeOp(_ value: String) -> Bool {
        consumeNext(Operator.self, matching: value)
    }
    
    func consumeIdent() -> (token: Token, value: Identifier)? {
        consumeNext(Identifier.self)
    }
}
