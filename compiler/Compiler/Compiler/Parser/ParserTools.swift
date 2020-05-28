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
    
    func declareGlobal(_ declaration: Ast) {
        let name: String
        if let proc = declaration as? ProcedureDeclaration { name = proc.name }
        else if let variable = declaration as? VariableDeclaration { name = variable.id }
        else { fatalError("Only variables and procedures can be declared at global scope") }
        global_declarations[name] = declaration
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
        advance()
        guard tokens.count > i else { return false }
        token = tokens[i]
        return true
    }
    
    /// Peeks at the `next` token
    func peekNext() -> Token? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        return tokens[nextIndex]
    }
    
    /// checks if `next token's value` is of the type passed, then eats if if it does
    /// if not, does nothing and returns nil
    func consumeNext<T: TokenValue>(_ value: T.Type) -> (token: Token, value: T)? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        token = tokens[nextIndex]
        if let value = token.value as? T {
            advance()
            return (token, value)
        }
        return nil
    }
    
    /// checks if `next char` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consumeNext(where compare: (TokenValue)->Bool) -> Token? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        token = tokens[nextIndex]
        if compare(token.value) {
            advance()
            return token
        }
        return nil
    }
    
    /// checks if `next char` exists, is a string-value token, and matches the passed value, then eats it if it does
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
