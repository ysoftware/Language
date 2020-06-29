//
//  Lexer.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

fileprivate let punctuators: [[Character]] = [
    "...", ".", ":", "(", ")", "{", "}", "[", "]", "->"
].map { Array($0) }

fileprivate let operators: [[Character]] = [
    ":=", "==", "!=", "<=", ">=", "&&", "||", ">", "<",
    "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<=",
    "-", "+", "/", "&", "*", "%", "..", "="
].map { Array($0) }

fileprivate let separators: [[Character]] = [
    "\n", " ", ";", ","
].map { Array($0) }

fileprivate let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
fileprivate let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
fileprivate let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))


final class Lexer {
    
    internal init(fileName: String? = nil, _ string: String) {
        self.fileName = fileName
        self.characters = Array(string)
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
    
    func analyze() throws -> LexerOutput {    
        loop: while stringCount > i {
            switch char {
                
            case "\"":
                let start = cursor
                // STRING LITERAL
                
                func isNextThreeQuotes(after n: Int = 0) -> Bool {
                    guard characters.count > i+2+n else { return false }
                    return characters[i+n] == "\"" && characters[i+1+n] == "\"" && characters[i+2+n] == "\""
                }
                
                let isMultiline = isNextThreeQuotes()
                if isMultiline {
                    nextChar(3)
                    if !consume("\n") {
                        throw error(.newlineExpectedBeforeMultilineStringLiteral, cursor, cursor)
                    }
                }
                else {
                    if !nextChar() { throw error(.unexpectedEndOfFile, cursor, cursor) }
                }
                
                
                var value = ""
                while stringCount > i {
                    if char == "\n" { /* @Todo: wtf is this? */ }
                    
                    if char == "\\" {
                        guard let next = peekNext()
                            else { throw error(.unexpectedEndOfFile, cursor, cursor) }
                        
                        switch next {
                        case "0":  value.append(Character(UnicodeScalar(0)))
                        case "n":  value.append("\n")
                        case "r":  value.append("\r")
                        case "\\": value.append("\\")
                        case "t":  value.append("\t")
                        case "\"": value.append("\"")
                        default: throw error(.unexpectedCharacterToEscape, cursor, cursor)
                        }
                        if !nextChar() || !nextChar() { throw error(.unexpectedEndOfFile, cursor, cursor) }
                        continue
                    }
                    
                    if isMultiline {
                        if peekNext() == nil { throw error(.unexpectedEndOfFile, cursor, cursor) }
                        else if isNextThreeQuotes() {
                            throw error(.newlineExpectedAfterMultilineStringLiteral, cursor, cursor)
                        }
                        else if char == "\n", isNextThreeQuotes(after: 1) {
                            nextChar(4)
                            if let next = peekNext(), next != "\n", next != ";" {
                                throw error(.newlineExpectedAfterMultilineStringLiteral, cursor, cursor)
                            }
                            else {
                                append(TokenLiteral(value: .string(value: value)), start, cursor)
                                break
                            }
                        }
                    }
                    else {
                        if consume(string: ["\""]) {
                            append(TokenLiteral(value: .string(value: value)), start, cursor)
                            break
                        }
                        else if peekNext() == "\n" { throw error(.newLineInStringLiteral, cursor, cursor) }
                    }
                    
                    value.append(char)
                    if !nextChar() { throw error(.unexpectedEndOfFile, cursor, cursor) }
                }
                
            case ";",  ",":
                // SEPARATORS
                let start = cursor
                append(Separator(value: String(char)), start, cursor)
                
            case lowercaseRange, uppercaseRange, "_", "#", "`":
                // KEYWORDS / IDENTIFIERS / DIRECTIVES / BOOL LITERALS
                
                let start = cursor
                let isDirective = consume(string: ["#"])
                if isDirective {
                    if !nextChar() { throw error(.emptyDirectiveName, start, cursor) }
                    else if char == " " { throw error(.emptyDirectiveName, start, cursor) }
                    else if !lowercaseRange.contains(char)
                        && !uppercaseRange.contains(char) && char != "_" {
                        throw error(.unexpectedDirectiveName, start, cursor)
                    }
                }
                
                var value = String(char)
                while let next = consumeNext(where: {
                    lowercaseRange.contains($0) || uppercaseRange.contains($0)
                        || numberRange.contains($0) || $0 == "_" || $0 == "*" || $0 == "`" }) {
                            value.append(next)
                }
                
                let isNotKeyword = value.first == "`" && value.last == "`" && value.count >= 3
                if isNotKeyword {
                    value = String(value[value.startIndex(offsetBy: 1)..<value.endIndex(offsetBy: -1)])
                }
                
                if let idx = value.firstIndex(of: "`") {
                    let i = value.distance(from: value.startIndex, to: idx)
                    let c = start.advancingCharacter(by: i-1) // @Todo: weird to do this to get the right cursor
                    
                    throw error(.unexpectedCharacter, c, c)
                }
                
                if value == "void" { append(TokenLiteral(value: .void), start, start) }
                else if value == "null" { append(TokenLiteral(value: .null), start, cursor) }
                else if value == "true" { append(TokenLiteral(value: .bool(value: true)), start, cursor) }
                else if value == "false" { append(TokenLiteral(value: .bool(value: false)), start, cursor) }
                else if !isNotKeyword, let keyword = Keyword(rawValue: value) { append(keyword, start, cursor) }
                else if isDirective {
                    if value.isEmpty { throw error(.emptyDirectiveName, start, cursor) }
                    append(Directive(value: value), start, cursor)
                }
                else {
                    if value == "_" { throw error(.invalidIdentifierUnderscore, start, cursor) }
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
                let numLitSymbols = Array("_.e-")
                while let next = consumeNext(where: { numberRange.contains($0) || numLitSymbols.contains($0) }) {
                    if value.count >= 1 && next == "-" && value.last != "e" {
                        throw error(.unexpectedMinusInNumberLiteral, start, cursor)
                    }
                    else if next == "." && value.contains(".") || next == "e" && value.contains("e") {
                        throw error((next == "." ? .unexpectedDotInFloatLiteral : .unexpectedEInFloatLiteral), start, cursor)
                    }
                    if next == "_" { continue }
                    value.append(next)
                }
                
                if let next = peekNext() {
                    if !(separators + punctuators + operators).contains([next]) {
                        throw error(.unexpectedCharacter, start, cursor)
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
                if consume(string: ["/", "/"]) {
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
                    _ = Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                else if consume(string: ["/", "*"]) {
                    var commentLevel = 1
                    guard nextChar() else { break }
                    
                    while stringCount > i && commentLevel > 0 {
                        if consume(string: ["/", "*"]) {
                            commentLevel += 1
                            if commentLevel > 0 {
                                value.append("/*")
                            }
                        }
                        else if consume(string: ["*", "/"]) {
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
                    _ = Comment(value: value.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                let start = cursor
                if let value = consume(oneOf: punctuators) {
                    append(Punctuator(value: String(value)), start, cursor)
                }
                else if let value = consume(oneOf: operators) {
                    append(Operator(value: String(value)), start, cursor)
                }
                else if char.isWhitespace {
                    break
                }
                else {
                    print("Error: \(char)    [@Todo: rework lexer errors]")
                    
                    if !char.isASCII {
                        throw error(.nonASCIICharacter, start.withdrawingCharacter(), cursor)
                    }
                    else {
                        throw error(.unexpectedCharacter, start.withdrawingCharacter(), cursor)
                    }
                }
            }
            guard nextChar() else { append(EOF(), cursor, cursor); break }
        }
        return LexerOutput(tokens: tokens, linesProcessed: cursor.lineNumber)
    }
}
