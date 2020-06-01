//
//  LexerTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension Lexer {

    /// add this token to the return
    func append(_ value: TokenValue) {
        tokens.append(Token(value, start: startCursor, end: endCursor))
        startCursor = endCursor
    }
    
    /// returns the error set at the current point
    func error(_ error: LexerError.Message) -> Result<[Token], LexerError> {
        .failure(LexerError(fileName: fileName, cursor: endCursor, error))
    }
    
    /// advances the counter
    func advance(_ count: Int = 1) {
        i += count
        endCursor.advanceCharacter(by: count)
    }
    
    /// advances the counter and sets `char` to the next character in string
    @discardableResult
    func nextChar() -> Bool {
        advance()
        guard string.count > i else { return false }
        char = string[i]
        return true
    }
    
    /// Peeks at the `next` character
    func peekNext() -> Character? {
        let nextIndex = i + 1
        guard string.count > nextIndex else { return nil }
        return string[nextIndex]
    }
    
    /// checks if `next char` exists and matches, then eats it if it does
    /// if not, does nothing and returns false
    func consumeNext(_ character: Character) -> Bool {
        consumeNext(where: { $0 == character }) != nil
    }
    
    /// checks if `next char` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consumeNext(where compare: (Character)->Bool) -> Character? {
        let nextIndex = i + 1
        guard string.count > nextIndex else { return nil }
        let char = string[nextIndex]
        if compare(char) {
            advance()
            return char
        }
        return nil
    }
    
    /// checks if the string
    /// matches `current and subsequent` characters
    func consume(string: String) -> Bool {
        consume(oneOf: [string]) != nil
    }
    
    /// checks if one of the strings in the array
    /// matches `current and subsequent` characters
    func consume(oneOf array: [String]) -> String? {
        var leftValues = array
        var index = 0
        var query = String(char)
        while string.count > i + index {
            let filtered = leftValues.filter { $0.count >= index && $0.starts(with: query) }
            if filtered.isEmpty {
                let prevQuery = String(query[query.startIndex..<query.endIndex(offsetBy: -1)])
                if leftValues.contains(prevQuery) {
                    advance(prevQuery.count - 1)
                    return prevQuery
                }
                return nil
            }
            leftValues = filtered
            if leftValues.count == 1, leftValues[0] == query {
                advance(query.count - 1)
                return query
            }
            index += 1
            guard string.count > i + index else { return nil }
            query.append(string[i + index])
        }
        return nil
    }
}
