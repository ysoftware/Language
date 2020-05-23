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

        // Constants
        
        let punctuators = [".", ":", "(", ")", "{", "}", "[", "]", "->", "..."]
        let operators = ["-", "+", "/", "*", "..", "=", ":=",
                         "==", "!=", "<=", ">=", "&&", "||",
                         "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<="]
        
        let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
        let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
        let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
        
        // Variables
        
        var tokens: [Token] = []
        var lineNumber = 0
        var characterOnLine = 0
        var i = 0
        var char = string[i]
        
        // Methods
        
        /// returns the error set at the current point
        func error(_ error: LexerError.Message) -> Result<[Token], LexerError> {
            .failure(LexerError(filename: filename, lineNumber: lineNumber,
                                character: characterOnLine, error))
        }
        
        /// advances the counter
        func advance(_ count: Int = 1) {
            i += count
            characterOnLine += count
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
                let nextChar = string[i + index]
                query.append(nextChar)
            }
            return nil
        }
        
        // Cycle
        
        while string.count > i {
            switch char {

            case "\"":
                // STRING LITERAL

                let isMultiline = consume(string: "\"\"\"")
                if isMultiline, !consumeNext("\n") {
                    return error(.newlineExpectedBeforeMultilineStringLiteral)
                }
                else {
                    nextChar()
                }
                
                var value = ""
                while string.count > i {
                    if char == "\n" {
                        lineNumber += 1
                        characterOnLine = 0
                    }
                    
                    if isMultiline {
                        if peekNext() == nil {
                            return error(.unexpectedEndOfFile)
                        }
                        else if consume(string: "\"\"\"") {
                            return error(.newlineExpectedAfterMultilineStringLiteral)
                        }
                        else if consume(string: "\n\"\"\"") {
                            if let next = peekNext(), next != "\n" {
                                return error(.newlineExpectedAfterMultilineStringLiteral)
                            }
                            else {
                                tokens.append(.literal(value: .string(value: value)))
                                break
                            }
                        }
                    }
                    else {
                        if consume(string: "\"") {
                            tokens.append(.literal(value: .string(value: value)))
                            break
                        }
                        else if consume(string: "\n") {
                            return error(.newLineInStringLiteral)
                        }
                    }
                    
                    value.append(char)
                    nextChar()
                }
            
            case "\n":
                lineNumber += 1
                characterOnLine = 0
                
            case ";",  ",":
                // SEPARATORS
                tokens.append(.separator(value: String(char)))
                
            case lowercaseRange, uppercaseRange, "_", "#":
                // KEYWORDS / IDENTIFIERS / DIRECTIVES
                
                let isDirective = consume(string: "#")
                if isDirective {
                    if !nextChar() {
                        return error(.emptyDirectiveName)
                    }
                    else if char == " " {
                        return error(.emptyDirectiveName)
                    }
                    else if !lowercaseRange.contains(char) && !uppercaseRange.contains(char) && char != "_" {
                       return error(.unexpectedDirectiveName)
                    }
                }
                
                var value = String(char)
                while let next = consumeNext(where: {
                    lowercaseRange.contains($0)
                        || uppercaseRange.contains($0)
                        || numberRange.contains($0)
                        || $0 == "_" }) {
                            value.append(next)
                }
                
                if isDirective {
                    if value.isEmpty {
                        return error(.emptyDirectiveName)
                    }
                    tokens.append(.directive(value: value))
                }
                else if keywords.contains(value) {
                    tokens.append(.keyword(value: value))
                }
                else {
                    tokens.append(.identifier(value: value))
                }
                
            case numberRange, ".", "-":
                // NUMBER LITERALS
                
                // if this and the next characters are both not numbers
                // @Note: this will fail "---1", and maybe we don't need it
                if !numberRange.contains(char), let next = peekNext(), !numberRange.contains(next) {
                    fallthrough
                }
                
                var value = String(char)
                while let next = consumeNext(where: { numberRange.contains($0) || $0 == "." || $0 == "e"}) {
                    if next == "." && value.contains(".") || next == "e" && value.contains("e") {
                        return error(next == "." ? .unexpectedDotInFloatLiteral : .unexpectedEInFloatLiteral)
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
                
                // @Note: we fallthrough to here from the case above
                // can expect ".", "e", "-" and number characters
                
                var value = ""
                if consume(string: "//") {
                    nextChar()
                    
                    while string.count > i {
                        if consume(string: "\n") {
                            lineNumber += 1
                            characterOnLine = 0
                            break
                        }
                        else {
                            value.append(char)
                            nextChar()
                        }
                    }
                    tokens.append(.comment(value:
                        value.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                else if consume(string: "/*") {
                    var commentLevel = 1
                    nextChar()
                    
                    while string.count > i && commentLevel > 0 {
                        if consume(string: "/*") {
                            commentLevel += 1
                            if commentLevel > 0 {
                                value.append("/*")
                            }
                        }
                        else if consume(string: "*/") {
                            commentLevel -= 1
                            if commentLevel > 0 {
                                value.append("*/")
                            }
                        }
                        else if consume(string: "\n") {
                            lineNumber += 1
                            characterOnLine = 0
                            value.append("\n")
                        }
                        else {
                            value.append(char)
                        }
                        nextChar()
                    }
                    tokens.append(.comment(value:
                        value.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                if let value = consume(oneOf: punctuators) {
                    tokens.append(.punctuator(value: value))
                }
                else if let value = consume(oneOf: operators) {
                    tokens.append(.operator(value: value))
                }
            }
            nextChar()
        }
        return .success(tokens)
    }
}
