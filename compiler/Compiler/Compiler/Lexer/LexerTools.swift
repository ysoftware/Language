//
//  LexerTools.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 28.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct LexerOutput {
    
    let tokens: [Token]
    let linesProcessed: Int
}

extension Lexer {

    /// add this token to the return
    @inline(__always)
    func append(_ value: TokenValue, _ start: Cursor, _ end: Cursor) {
        tokens.append(Token(value, start: start, end: end))
    }
    
    /// returns the error set at the current point
    @inline(__always)
    func error(_ error: LexerError.Message, _ start: Cursor, _ end: Cursor) -> LexerError {
        LexerError(fileName: fileName, startCursor: start, endCursor: end, error)
    }
    
    /// advances the counter
    @inline(__always)
    func advance(_ count: Int = 1) {
        i += count
        // @Todo: this doesn't check every the character on the way
        if char.isNewline {
            cursor.advanceLine()
        }
        else {
            cursor.advanceCharacter(by: count)
        }
    }
    
    @inline(__always) @discardableResult // @Todo test
    func eatSpaces(eatNewLines: Bool = true) -> Bool {
        var didEat = false
        repeat {
            if char.isWhitespace || (eatNewLines && char.isNewline) {
                didEat = true
            }
            if !nextChar() { break }
        } while true
        return didEat
    }
    
    /// advances the counter and sets `char` to the next character in string
    @discardableResult @inline(__always)
    func nextChar(_ n: Int = 1) -> Bool {
        for _ in 0..<n {
            advance()
            guard stringCount > i else {
                return false
            }
            char = characters[i]
        }
        return true
    }
    
    /// Peeks at the `next` character
    @inline(__always)
    func peekNext(_ n: Int = 1) -> Character? {
        let nextIndex = i + n
        guard stringCount > nextIndex else { return nil }
        return characters[nextIndex]
    }
    
    /// checks if `next char` exists and matches, then eats it if it does
    /// if not, does nothing and returns false
    @inline(__always)
    func consumeNext(_ character: Character) -> Bool {
        consumeNext(where: { $0 == character }) != nil
    }
    
    /// checks if `next char` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consumeNext(where compare: (Character)->Bool) -> Character? {
        let nextIndex = i + 1
        guard stringCount > nextIndex else { return nil }
        let char = characters[nextIndex]
        if compare(char) {
            advance()
            return char
        }
        return nil
    }
    
    /// checks if `char` matches, then eats it if it does
    /// if not, does nothing and returns false
    func consume(_ character: Character) -> Bool {
        if char == character {
            nextChar()
            return true
        }
        return false
    }
    
    /// checks if the string
    /// matches `current and subsequent` characters
    func consume(string: [Character]) -> Bool {
        let count = string.count
        
        var index = 0
        while count > index {
            guard stringCount > i + index, characters[i + index] == string[index] else {
                return false
            }
            index += 1
        }
        
        nextChar(count-1)
        return true
    }
    
    // @Speed: this is extremely slow
    /// checks if one of the strings in the array
    /// matches `current and subsequent` characters
    func consume(oneOf array: [[Character]]) -> [Character]? {
        for s in array {
            if consume(string: s) {
                return s
            }
        }
        return nil
    }
}
