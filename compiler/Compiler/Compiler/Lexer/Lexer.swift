//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

fileprivate let punctuators = [".", ":", "(", ")", "{", "}", "[", "]", "->", "..."]
fileprivate let operators = ["-", "+", "/", "*", "..", "=", ":=",
                             "==", "!=", "<=", ">=", "&&", "||",
                             "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<="]

fileprivate let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
fileprivate let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
fileprivate let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))


class Lexer {
    
    internal init(fileName: String? = nil, _ string: String) {
        self.fileName = fileName
        self.string = string
        self.char = string[i]
    }
    
    let fileName: String?
    let string: String

    // Variables
    
    var tokens: [Token] = []
    var startCursor = Cursor()
    var endCursor = Cursor()
    var i = 0
    var char: Character
    
    func analyze() -> Result<[Token], LexerError> {    
        while string.count > i {
            switch char {
                
            case "\"":
                // STRING LITERAL
                
                let isMultiline = consume(string: "\"\"\"")
                if isMultiline, !consumeNext("\n") {
                    return error(.newlineExpectedBeforeMultilineStringLiteral)
                }
                else if !nextChar() {
                    return error(.unexpectedEndOfFile)
                }
                
                var value = ""
                while string.count > i {
                    if char == "\n" {
                        endCursor.advanceLine()
                    }
                    
                    if isMultiline {
                        if peekNext() == nil { return error(.unexpectedEndOfFile) }
                        else if consume(string: "\"\"\"") {
                            return error(.newlineExpectedAfterMultilineStringLiteral)
                        }
                        else if consume(string: "\n\"\"\"") {
                            if let next = peekNext(), next != "\n" {
                                return error(.newlineExpectedAfterMultilineStringLiteral)
                            }
                            else {
                                append(TokenLiteral(value: .string(value: value)))
                                break
                            }
                        }
                    }
                    else {
                        if consume(string: "\"") {
                            append(TokenLiteral(value: .string(value: value)))
                            break
                        }
                        else if consume(string: "\n") { return error(.newLineInStringLiteral) }
                    }
                    
                    value.append(char)
                    if !nextChar() { return error(.unexpectedEndOfFile) }
                }
                
            case "\n":
                startCursor.advanceLine()
                endCursor.advanceLine()
                
            case ";",  ",":
                // SEPARATORS
                append(Separator(value: String(char)))
                
            case lowercaseRange, uppercaseRange, "_", "#":
                // KEYWORDS / IDENTIFIERS / DIRECTIVES / BOOL LITERALS
                
                let isDirective = consume(string: "#")
                if isDirective {
                    if !nextChar() { return error(.emptyDirectiveName) }
                    else if char == " " { return error(.emptyDirectiveName) }
                    else if !lowercaseRange.contains(char)
                        && !uppercaseRange.contains(char) && char != "_" {
                        return error(.unexpectedDirectiveName)
                    }
                }
                
                var value = String(char)
                while let next = consumeNext(where: {
                    lowercaseRange.contains($0) || uppercaseRange.contains($0)
                        || numberRange.contains($0) || $0 == "_" }) {
                            value.append(next)
                }
                
                if value == "true" { append(TokenLiteral(value: .bool(value: true))) }
                else if value == "false" { append(TokenLiteral(value: .bool(value: false))) }
                else if let keyword = Keyword(rawValue: value) { append(keyword) }
                else if isDirective {
                    if value.isEmpty { return error(.emptyDirectiveName) }
                    append(Directive(value: value))
                }
                else { append(Identifier(value: value)) }
                
            case numberRange, ".", "-":
                // NUMBER LITERALS
                
                // if this and the next characters are both not numbers
                // @Note: this will fail "---1", and maybe we don't need it
                if !numberRange.contains(char), let next = peekNext(), !numberRange.contains(next) {
                    fallthrough
                }
                
                var value = String(char)
                while let next = consumeNext(where: { numberRange.contains($0) || $0 == "." || $0 == "e" || $0 == "-" }) {
                    if value.count >= 1 && next == "-" && value.last != "e" {
                        return error(.unexpectedMinusInNumberLiteral)
                    }
                    else if next == "." && value.contains(".") || next == "e" && value.contains("e") {
                        return error(next == "." ? .unexpectedDotInFloatLiteral : .unexpectedEInFloatLiteral)
                    }
                    value.append(next)
                }
                
                if value == "-" || value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    append(TokenLiteral(value: .float(value: Float(value)!)))
                }
                else {
                    append(TokenLiteral(value: .int(value: Int(value)!)))
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
                            endCursor.advanceLine()
                            break
                        }
                        else {
                            value.append(char)
                            nextChar()
                        }
                    }
                    append(Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines)))
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
                            endCursor.advanceLine()
                            value.append("\n")
                        }
                        else {
                            value.append(char)
                        }
                        nextChar()
                    }
                    append(Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                if let value = consume(oneOf: punctuators) {
                    append(Punctuator(value: value))
                }
                else if let value = consume(oneOf: operators) {
                    append(Operator(value: value))
                }
                else if char == " " {
                    startCursor.advanceCharacter()
                }
                else {
                    // for some reason?
                    return error(.unexpectedCharacter)
                }
            }
            nextChar()
        }
        return .success(tokens)
    }
}
