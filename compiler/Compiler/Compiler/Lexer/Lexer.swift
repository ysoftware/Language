//
//  Lexer.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

// @Todo: properly eat whitespaces

fileprivate let punctuators = [".", ":", "(", ")", "{", "}", "[", "]", "->", "..."]
fileprivate let operators = ["-", "+", "/", "*", "%", "..", "=", ":=",
                             "==", "!=", "<=", ">=", "&&", "||", ">", "<",
                             "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<="]
fileprivate let separators = ["\n", " ", ";", ","]

fileprivate let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
fileprivate let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
fileprivate let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))


final class Lexer {
    
    internal init(fileName: String? = nil, _ string: String) {
        self.fileName = fileName
        self.characters = string.dropLast(0) // hack to convert string to character array
        self.char = string[i]
        self.stringCount = string.count
    }
    
    let fileName: String?
    let characters: [Character]
    let stringCount: Int

    // Variables
    
    var tokens: [Token] = []
    var cursor = Cursor()
    var i = 0
    var char: Character
    
    func analyze() -> Result<LexerOutput, LexerError> {    
        loop: while stringCount > i {
            switch char {
                
            case "\"":
                let start = cursor
                // STRING LITERAL
                
                let isMultiline = consume(string: "\"\"\"")
                if isMultiline, !consumeNext("\n") {
                    return error(.newlineExpectedBeforeMultilineStringLiteral, cursor, cursor)
                }
                if !nextChar() { return error(.unexpectedEndOfFile, cursor, cursor) }
                
                var value = ""
                while stringCount > i {
                    if char == "\n" { }
                    
                    if consume(string: "\\") {
                        guard let next = peekNext()
                            else { return error(.unexpectedEndOfFile, cursor, cursor) }
                        
                        switch next {
                        case "0":  value.append(Character(UnicodeScalar(0)))
                        case "n":  value.append("\n")
                        case "r":  value.append("\r")
                        case "\\": value.append("\\")
                        case "t":  value.append("\t")
                        case "\"": value.append("\"")
                        default: return error(.unexpectedCharacterToEscape, cursor, cursor)
                        }
                        if !nextChar() || !nextChar() { return error(.unexpectedEndOfFile, cursor, cursor) }
                        continue
                    }
                    
                    if isMultiline {
                        if peekNext() == nil { return error(.unexpectedEndOfFile, cursor, cursor) }
                        else if consume(string: "\"\"\"") {
                            return error(.newlineExpectedAfterMultilineStringLiteral, cursor, cursor)
                        }
                        else if consume(string: "\n\"\"\"") {
                            if let next = peekNext(), next != "\n", next != ";" {
                                return error(.newlineExpectedAfterMultilineStringLiteral, cursor, cursor)
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
                        else if peekNext() == "\n" { return error(.newLineInStringLiteral, cursor, cursor) }
                    }
                    
                    value.append(char)
                    if !nextChar() { return error(.unexpectedEndOfFile, cursor, cursor) }
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
                        || numberRange.contains($0) || $0 == "_" || $0 == "*" }) {
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
                
                if let next = peekNext() {
                    if !(separators + punctuators + operators).contains(String(next)) { // @Speed: this is extremely slow
                        return error(.unexpectedCharacter, start, cursor)
                    }
                }
                
                if value == "-" || value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    append(TokenLiteral(value: .float(value: Float64(value)!)), start, cursor)
                }
                else {
                    append(TokenLiteral(value: .int(value: Int(value)!)), start, cursor)
                }
                
            case "/":
                // COMMENTS
                
                // we fallthrough to here from the case above
                // can expect ".", "e", "-" and number characters
                let start = cursor
                var value = ""
                if consume(string: "//") {
                    guard nextChar() else { break }
                    
                    while stringCount > i {
                        if char == "\n" {
                            break
                        }
                        else {
                            value.append(char)
                            guard nextChar() else { break }
                        }
                    }
                    append(Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines)), start, cursor)
                }
                else if consume(string: "/*") {
                    var commentLevel = 1
                    guard nextChar() else { break }
                    
                    while stringCount > i && commentLevel > 0 {
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
                        else if char ==  "\n" {
                            value.append("\n")
                        }
                        else {
                            value.append(char)
                        }
                        guard nextChar() else { break }
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
            guard nextChar() else { append(EOF(), cursor, cursor); break }
        }
        return .success(LexerOutput(tokens: tokens, linesProcessed: cursor.lineNumber))
    }
}
