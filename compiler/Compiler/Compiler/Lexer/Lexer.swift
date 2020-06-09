//
//  Lexer.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

// @Todo: add EOF token - unfinished string literal results in crash
// @Todo: properly eat whitespaces

fileprivate let punctuators = [".", ":", "(", ")", "{", "}", "[", "]", "->", "..."]
fileprivate let operators = ["-", "+", "/", "*", "%", "..", "=", ":=",
                             "==", "!=", "<=", ">=", "&&", "||", ">", "<",
                             "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<="]

fileprivate let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
fileprivate let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
fileprivate let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))


final class Lexer {
    
    internal init(fileName: String? = nil, _ string: String) {
        self.fileName = fileName
        self.string = string
        self.char = string[i]
    }
    
    let fileName: String?
    let string: String

    // Variables
    
    var tokens: [Token] = []
    var cursor = Cursor()
    var i = 0
    var char: Character
    
    func analyze() -> Result<[Token], LexerError> {    
        loop: while string.count > i {
            switch char {
                
            case "\"":
                let start = cursor
                // STRING LITERAL
                
                let isMultiline = consume(string: "\"\"\"")
                if isMultiline, !consumeNext("\n") {
                    return error(.newlineExpectedBeforeMultilineStringLiteral, start, cursor)
                }
                else if !nextChar() {
                    return error(.unexpectedEndOfFile, start, cursor)
                }
                
                var value = ""
                while string.count > i {
                    if char == "\n" { }
                    
                    if isMultiline {
                        if peekNext() == nil { return error(.unexpectedEndOfFile, start, cursor) }
                        else if consume(string: "\"\"\"") {
                            return error(.newlineExpectedAfterMultilineStringLiteral, start, cursor)
                        }
                        else if consume(string: "\n\"\"\"") {
                            if let next = peekNext(), next != "\n" {
                                return error(.newlineExpectedAfterMultilineStringLiteral, start, cursor)
                            }
                            else {
                                append(TokenLiteral(value: .string(value: value)), start, cursor)
                                break
                            }
                        }
                    }
                    else {
                        if consume(string: "\"") {
                            append(TokenLiteral(value: .string(value: value)), start, cursor)
                            break
                        }
                        else if consume(string: "\n") { return error(.newLineInStringLiteral, start, cursor) }
                    }
                    
                    value.append(char)
                    if !nextChar() { return error(.unexpectedEndOfFile, start, cursor) }
                }
                
            case ";",  ",":
                // SEPARATORS
                let start = cursor
                append(Separator(value: String(char)), start, cursor)
                
            case lowercaseRange, uppercaseRange, "_", "#":
                // KEYWORDS / IDENTIFIERS / DIRECTIVES / BOOL LITERALS
                
                let start = cursor
                let isDirective = consume(string: "#")
                if isDirective {
                    if !nextChar() { return error(.emptyDirectiveName, start, cursor) }
                    else if char == " " { return error(.emptyDirectiveName, start, cursor) }
                    else if !lowercaseRange.contains(char)
                        && !uppercaseRange.contains(char) && char != "_" {
                        return error(.unexpectedDirectiveName, start, cursor)
                    }
                }
                
                var value = String(char)
                while let next = consumeNext(where: {
                    lowercaseRange.contains($0) || uppercaseRange.contains($0)
                        || numberRange.contains($0) || $0 == "_" }) {
                            value.append(next)
                }
                
                if value == "true" { append(TokenLiteral(value: .bool(value: true)), start, cursor) }
                else if value == "false" { append(TokenLiteral(value: .bool(value: false)), start, cursor) }
                else if let keyword = Keyword(rawValue: value) { append(keyword, start, cursor) }
                else if isDirective {
                    if value.isEmpty { return error(.emptyDirectiveName, start, cursor) }
                    append(Directive(value: value), start, cursor)
                }
                else {
                    if value == "_" { return error(.invalidIdentifierUnderscore, start, cursor) }
                    append(Identifier(value: value), start, cursor)
                }
                
            case numberRange, ".", "-":
                // NUMBER LITERALS
                
                let start = cursor
                
                // if this and the next characters are both not numbers
                if !numberRange.contains(char), let next = peekNext(), !numberRange.contains(next) {
                    fallthrough
                }
                
                var value = String(char)
                let numLitSymbols = "_.e-"
                while let next = consumeNext(where: { numberRange.contains($0) || numLitSymbols.contains($0) }) {
                    if value.count >= 1 && next == "-" && value.last != "e" {
                        return error(.unexpectedMinusInNumberLiteral, start, cursor)
                    }
                    else if next == "." && value.contains(".") || next == "e" && value.contains("e") {
                        return error((next == "." ? .unexpectedDotInFloatLiteral : .unexpectedEInFloatLiteral), start, cursor)
                    }
                    if next == "_" { continue }
                    value.append(next)
                }
                
                if value == "-" || value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    append(TokenLiteral(value: .float(value: Float(value)!)), start, cursor)
                }
                else {
                    append(TokenLiteral(value: .int(value: Int(value)!)), start, cursor)
                }
                
            case "/":
                // COMMENTS
                
                // @Todo: // comments fuck up cursors
                
                // @Note: we fallthrough to here from the case above
                // can expect ".", "e", "-" and number characters
                
                let start = cursor
                var value = ""
                if consume(string: "//") {
                    nextChar()
                    
                    while string.count > i {
                        if consume(string: "\n") {
                            cursor.advanceLine()
                            break
                        }
                        else {
                            value.append(char)
                            nextChar()
                        }
                    }
                    append(Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines)), start, cursor)
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
                            value.append("\n")
                        }
                        else {
                            value.append(char)
                        }
                        nextChar()
                    }
                    append(Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines)), start, cursor)
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                let start = cursor
                if let value = consume(oneOf: punctuators) {
                    append(Punctuator(value: value), start, cursor)
                }
                else if let value = consume(oneOf: operators) {
                    append(Operator(value: value), start, cursor)
                }
                else if char.isWhitespace {
                    break
                }
                else {
                    // for some reason?
                    print(char)
                    return error(.unexpectedCharacter, cursor, cursor)
                }
            }
            nextChar()
        }
        return .success(tokens)
    }
}
