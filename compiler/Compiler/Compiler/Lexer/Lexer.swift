//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

enum Lexer {
    
    static func analyze(filename: String = "<no file>", _ string: String) -> Result<[Token], LexerError> {
        let symbols: [Character] = [ ":", "+", "-", "*", "/", "=", ">", "<", ".", "#", "!", "&", "{", "}", "(", ")",  "[", "]"]
        let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
        let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
        let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
        
        var tokens: [Token] = []
        var lineNumber = 0
        var characterOnLine = 0
        var i = 0
        var char = string[i]
        
        func advance(_ count: Int = 1) {
            i += count
            characterOnLine += count
        }
        
        func nextChar() {
            advance()
            guard string.count > i else { return }
            char = string[i]
        }
        
        func lookahead() -> Character {
            string[i + 1]
        }
        
        // checks if next char exists and matches, then eats it if it does
        // if not, does nothing and returns nil
        func match(_ compare: (Character)->Bool) -> Character? {
            let nextIndex = i + 1
            guard string.count > nextIndex else { return nil }
            let char = string[nextIndex]
            if compare(char) {
                advance()
                return char
            }
            return nil
        }
        
        // checks if one of the strings in the array
        // matches current and subsequent characters
        func match(oneOf array: [String]) -> String? {
            var leftValues = array
            var index = 0
            var query = String(char)
            
            while string.count > i + index {
                let filtered = leftValues.filter {
                    $0.count >= index && $0.starts(with: query)
                }
                
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
                let nextChar = string[i + index]
                query += String(nextChar)
            }
            return nil
        }
        
        
        while i < string.count {
            switch char {
                
                // @Todo: comment, folded comment
                // @Todo: string literal
                
            case "\n":
                lineNumber += 1
                characterOnLine = 0
                
            case ";",  ",":
                // SEPARATORS
                tokens.append(.separator(symbol: String(char)))
                
            case lowercaseRange, uppercaseRange, "_":
                // KEYWORDS / IDENTIFIERS
                var value = String(char)
                
                while let next = match({
                    lowercaseRange.contains($0)
                        || uppercaseRange.contains($0)
                        || numberRange.contains($0)
                        || $0 == "_" }) {
                            value.append(next)
                }
                
                if keywords.contains(value) {
                    tokens.append(.keyword(name: value))
                }
                else {
                    tokens.append(.identifier(name: value))
                }
                
            case numberRange, ".", "-":
                // NUMBER LITERALS
                var value = String(char)
                
                // this is not a number literal
                if !numberRange.contains(char) && !numberRange.contains(lookahead()) {
                    fallthrough
                }
                                
                while let next = match({ numberRange.contains($0) || $0 == "." || $0 == "e"}) {
                    if next == "." && value.contains(".") || next == "e" && value.contains("e") {
                        return .failure(
                            LexerError(filename: filename,
                                       lineNumber: lineNumber,
                                       character: characterOnLine,
                                       "Unexpected \"\(next)\" in the middle of a number literal"))
                    }
                    value.append(next)
                }
                
                if value == "-" || value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    tokens.append(.literal(value: .float(value: Float(value)!)))
                }
                else {
                    tokens.append(.literal(value: .int(value: Int(value)!)))
                }
                
            case _ where symbols.contains(char):
                // PUNCTUATORS, OPERATORS
                
                let punctuators = ["->", "...", "[", "]", "(", ")", "{", "}", ":"]

                if let value = match(oneOf: punctuators) {
                    tokens.append(.punctuator(character: value))
                    break
                }
                
                let operators = ["..", "=", ":=",
                                 "&&", "||", "!=", "==", "^=",
                                 ">>", "<<", ">>=", "<<=",
                                 "<=", ">=", "+=", "-=", "*=", "/=", "%="]
                
                if let value = match(oneOf: operators) {
                    tokens.append(.punctuator(character: value))
                    break
                }
                
                fallthrough
                
                // @Todo: #[.]  for directive
                
            default:
                break
            }
            nextChar()
        }
        
        return .success(tokens)
    }
}


