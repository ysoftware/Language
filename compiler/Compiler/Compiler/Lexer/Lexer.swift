//
//  Lexer.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

final class Lexer {
    
    internal init(fileName: String? = nil, _ string: String) {
        self.fileName = fileName

        self.characters = string.cString(using: .ascii) ?? []
        self.stringCount = characters.count

        // @Todo: bring back this error
//        if !char.isASCII {
//            throw error(.nonASCIICharacter, start.withdrawingCharacter(), cursor)
//        }
        if stringCount > 0 { self.char = characters[i] }
        else { char = C.space }
    }
    
    let fileName: String?
    let characters: [CChar]
    let stringCount: Int

    // Variables
    
    var tokens: [Token] = []
    var cursor = Cursor()
    var i = 0
    var char: CChar
    
    func analyze() throws -> LexerOutput {    
        loop: while stringCount > i {
            switch char {
                
            case C.quote:
                let start = cursor
                // STRING LITERAL
                
                func isNextThreeQuotes(after n: Int = 0) -> Bool {
                    guard characters.count > i+2+n else { return false }
                    return characters[i+n] == C.quote && characters[i+1+n] == C.quote && characters[i+2+n] == C.quote
                }
                
                let isMultiline = isNextThreeQuotes()
                if isMultiline {
                    nextChar(3)
                    if !consume(C.newline) {
                        throw error(.newlineExpectedBeforeMultilineStringLiteral, cursor, cursor)
                    }
                }
                else {
                    if !nextChar() { throw error(.unexpectedEndOfFile, cursor, cursor) }
                }
                
                
                var value: [CChar] = []
                while stringCount > i {
                    if char == C.newline { /* @Todo: wtf is this? */ }
                    
                    if char == C.backslash {
                        guard let next = peekNext()
                            else { throw error(.unexpectedEndOfFile, cursor, cursor) }
                        
                        switch next {
                        case C.zero:  value.append(0)
                        case C.n:  value.append(C.newline)
                        case C.r:  value.append(C.return)
                        case C.backslash: value.append(C.backslash)
                        case C.t:  value.append(C.tab)
                        case C.quote: value.append(C.quote)
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
                        else if char == C.newline, isNextThreeQuotes(after: 1) {
                            nextChar(4)
                            if let next = peekNext(), next != C.newline, next != C.semicolon {
                                throw error(.newlineExpectedAfterMultilineStringLiteral, cursor, cursor)
                            }
                            else {
                                append(TokenLiteral(value: .string(value: C.string(from: value))), start, cursor)
                                break
                            }
                        }
                    }
                    else {
                        if consume(string: [C.quote]) {
                            append(TokenLiteral(value: .string(value: C.string(from: value))), start, cursor)
                            break
                        }
                        else if peekNext() == C.newline { throw error(.newLineInStringLiteral, cursor, cursor) }
                    }
                    
                    value.append(char)
                    if !nextChar() { throw error(.unexpectedEndOfFile, cursor, cursor) }
                }
                
            case C.semicolon, C.comma:
                // SEPARATORS
                let start = cursor
                append(Separator(value: C.string(from: [char])), start, cursor)
                
            case lowercaseRange, uppercaseRange, C.underscore, C.pound, C.accent:
                // KEYWORDS / IDENTIFIERS / DIRECTIVES / BOOL LITERALS
                
                let start = cursor
                let isDirective = consume(string: [C.pound])
                if isDirective {
                    if !nextChar() { throw error(.emptyDirectiveName, start, cursor) }
                    else if char == C.space { throw error(.emptyDirectiveName, start, cursor) }
                    else if !lowercaseRange.contains(char)
                        && !uppercaseRange.contains(char) && char != C.underscore {
                        throw error(.unexpectedDirectiveName, start, cursor)
                    }
                }
                
                var value = [char]
                while let next = consumeNext(where: {
                    let isMatching = lowercaseRange.contains($0) || uppercaseRange.contains($0)
                    || numberRange.contains($0) || $0 == C.underscore || $0 == C.asterisk || $0 == C.accent
                    let isLegal = value.last != C.asterisk || value.last == C.asterisk && $0 == C.asterisk // only allowed trailing asterisks
                    return isMatching && isLegal
                }) {
                    value.append(next)
                }
                
                let isNotKeyword = value.first == C.accent && value.last == C.accent && value.count >= 3
                if isNotKeyword {
                    value = Array(value[1..<value.count-1])
                }
                
                if let idx = value.firstIndex(of: C.accent) {
                    let i = value.distance(from: value.startIndex, to: idx)
                    let c = start.advancingCharacter(by: i-1) // @Todo: weird to do this to get the right cursor
                    
                    print("Error: \(printChar)    [@Todo: rework lexer errors 1]")
                    throw error(.unexpectedCharacter, c, c)
                }
                
                if value == C.void { append(TokenLiteral(value: .void), start, start) }
                else if value == C.null { append(TokenLiteral(value: .null), start, cursor) }
                else if value == C.true { append(TokenLiteral(value: .bool(value: true)), start, cursor) }
                else if value == C.false { append(TokenLiteral(value: .bool(value: false)), start, cursor) }
                else if !isNotKeyword, let keyword = Keyword(rawValue: C.string(from: value)) {
                    append(keyword, start, cursor) // @Speed: slow parsing of keywords
                }
                else if isDirective {
                    if value.isEmpty { throw error(.emptyDirectiveName, start, cursor) }
                    append(Directive(value: C.string(from: value)), start, cursor)
                }
                else {
                    if value == [C.underscore] { throw error(.invalidIdentifierUnderscore, start, cursor) }
                    append(Identifier(value: C.string(from: value)), start, cursor)
                }
                
            case numberRange, C.dot, C.dash:
                // NUMBER LITERALS
                
                let start = cursor
                
                // if this and the next characters are both not numbers
                if !numberRange.contains(char), let next = peekNext(), !numberRange.contains(next) {
                    fallthrough
                }
                
                var value = [char]
                let numLitSymbols = [C.underscore, C.dot, C.e, C.dash]
                while let next = consumeNext(where: { numberRange.contains($0) || numLitSymbols.contains($0) }) {
                    if value.count >= 1 && next == C.dash && value.last != C.e {
                        throw error(.unexpectedMinusInNumberLiteral, start, cursor)
                    }
                    else if next == C.dot && value.contains(C.dot) || next == C.e && value.contains(C.e) {
                        throw error((next == C.dot ? .unexpectedDotInFloatLiteral : .unexpectedEInFloatLiteral), start, cursor)
                    }
                    if next == C.underscore { continue }
                    value.append(next)
                }
                
                if let next = peekNext() {
                    if !(separators + punctuators + operators).contains([next]) {
                        print("Error: \(printChar)    [@Todo: rework lexer errors 3]")
                        throw error(.unexpectedCharacterInNumber, cursor, cursor)
                    }
                }
                
                if value == [C.dash] || value.filter({ $0 != C.dot }).isEmpty {
                    fallthrough
                }
                else if value.contains(C.e) || value.contains(C.dot) {
                    append(TokenLiteral(value: .float(value: Float64(C.string(from: value))!)), start, cursor)
                }
                else {
                    append(TokenLiteral(value: .int(value: Int(C.string(from: value))!)), start, cursor)
                }
                
            case C.slash:
                // COMMENTS
                
                // we fallthrough to here from the case above
                // can expect ".", "e", "-" and number characters
                var value: [CChar] = []
                if consume(string: [C.slash, C.slash]) {
                    guard nextChar() else { break }
                    
                    while stringCount > i {
                        if char == C.newline {
                            break
                        }
                        else {
                            value.append(char)
                            guard nextChar() else { break }
                        }
                    }
                    _ = Comment(value: C.string(from: value).trimmingCharacters(in: .whitespacesAndNewlines))
                }
                else if consume(string: C.slashAsterisk) {
                    var commentLevel = 1
                    guard nextChar() else { break }
                    
                    while stringCount > i && commentLevel > 0 {
                        if consume(string: C.slashAsterisk) {
                            commentLevel += 1
                            if commentLevel > 0 {
                                value.append(contentsOf: C.slashAsterisk)
                            }
                        }
                        else if consume(string: C.asteriskSlash) {
                            commentLevel -= 1
                            if commentLevel > 0 {
                                value.append(contentsOf: C.asteriskSlash)
                            }
                        }
                        else if char ==  C.newline {
                            value.append(C.newline)
                        }
                        else {
                            value.append(char)
                        }
                        guard nextChar() else { break }
                    }
                    _ = Comment(value: C.string(from: value).trimmingCharacters(in: .whitespacesAndNewlines))
                }
                else {
                    fallthrough
                }
                
            default:
                // PUNCTUATORS, OPERATORS
                let start = cursor
                if let value = consume(oneOf: punctuators) {
                    append(Punctuator(value: C.string(from: value)), start, cursor)
                }
                else if let value = consume(oneOf: operators) {
                    append(Operator(value: C.string(from: value)), start, cursor)
                }
                else if char == C.space || char == C.newline {
                    break
                }
                else if char == 0 {
                    append(EOF(), cursor, cursor)
                    break loop
                }
                else {
                    print("Error: \(printChar))    [@Todo: rework lexer errors 2]")
                    throw error(.unexpectedCharacter, start.withdrawingCharacter(), cursor)
                }
            }
            guard nextChar() else { break }
        }
        return LexerOutput(tokens: tokens, linesProcessed: cursor.lineNumber)
    }
}


