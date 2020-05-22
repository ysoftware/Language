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
        let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
        let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
        let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
        
        var tokens: [Token] = []
        
        var lineNumber = 0
        var characterOnLine = 0
        var i = 0
        var char = string[i]
        
        /// advances the counter
        func advance(_ count: Int = 1) {
            i += count
            characterOnLine += count
        }
        
        /// advances the counter and sets `char` to the next character in string
        func nextChar() {
            advance()
            guard string.count > i else { return }
            char = string[i]
        }
        
        /// Peeks at the `next` character
        func lookahead() -> Character? {
            guard string.count > i else { return nil }
            return string[i + 1]
        }
        
        /// checks if `next char` exists and matches, then eats it if it does
        /// if not, does nothing and returns false
        func matchNext(_ character: Character) -> Bool {
            matchNext(where: { $0 == character }) != nil
        }
        
        /// checks if `next char` exists and matches the predicate, then eats it if it does
        /// if not, does nothing and returns nil
        func matchNext(where compare: (Character)->Bool) -> Character? {
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
        func match(string: String) -> Bool {
            match(oneOf: [string]) != nil
        }
        
        /// checks if one of the strings in the array
        /// matches `current and subsequent` characters
        func match(oneOf array: [String]) -> String? {
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
                let nextChar = string[i + index]
                query.append(nextChar)
            }
            return nil
        }
        
        
        while i < string.count {
            switch char {

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
                
                while let next = matchNext(where: {
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
                
                // if this and the next characters are both not numbers
                // @Note: this will fail "---1", and maybe we don't need it
                if !numberRange.contains(char), let next = lookahead(), !numberRange.contains(next) {
                    fallthrough
                }
                
                while let next = matchNext(where: { numberRange.contains($0) || $0 == "." || $0 == "e"}) {
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
                
            case "/":
                // COMMENTS
                var commentString = ""
                
                // @Note: we fallthrough to here from the case above
                // can expect ".", "e" and number characters
                
                if match(string: "//") {
                    nextChar()
                    
                    while i < string.count {
                        if match(string: "\n") {
                            lineNumber += 1
                            characterOnLine = 0
                            break
                        }
                        else {
                            commentString.append(char)
                            nextChar()
                        }
                    }
                    tokens.append(.comment(text:
                        commentString.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                else if match(string: "/*") {
                    var commentLevel = 1
                    nextChar()
                    
                    while i < string.count && commentLevel > 0 {
                        if match(string: "/*") {
                            commentLevel += 1
                            if commentLevel > 0 {
                                commentString.append("/*")
                            }
                        }
                        else if match(string: "*/") {
                            commentLevel -= 1
                            if commentLevel > 0 {
                                commentString.append("*/")
                            }
                        }
                        else if match(string: "\n") {
                            lineNumber += 1
                            characterOnLine = 0
                            commentString.append("\n")
                        }
                        else {
                            commentString.append(char)
                        }
                        nextChar()
                    }
                    tokens.append(.comment(text:
                        commentString.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                
                let punctuators = ["->", "...", "[", "]", "(", ")", "{", "}", ":"]

                if let value = match(oneOf: punctuators) {
                    tokens.append(.punctuator(character: value))
                    break
                }
                
                let operators = ["-", "+", "/", "*",
                                 "..", "=", ":=",
                                 "&&", "||", "!=", "==", "^=",
                                 ">>", "<<", ">>=", "<<=",
                                 "<=", ">=", "+=", "-=", "*=", "/=", "%="]
                
                if let value = match(oneOf: operators) {
                    tokens.append(.operator(name: value))
                    break
                }
                
                break
                
                // @Todo: #[.]  for directive
                
            }
            nextChar()
        }
        
        return .success(tokens)
    }
}


