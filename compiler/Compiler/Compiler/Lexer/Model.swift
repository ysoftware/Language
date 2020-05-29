//
//  Model.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

enum LiteralToken: Equatable {
    
    static func == (lhs: LiteralToken, rhs: LiteralToken) -> Bool {
        switch (lhs, rhs) {
        case (.string(let v), .string(let v2)): return v == v2
        case (.float(let v), .float(let v2)): return v == v2
        case (.int(let v), .int(let v2)): return v == v2
        case (.bool(let v), .bool(let v2)): return v == v2
        default: return false
        }
    }
    
    case string(value: String)
    case float(value: Float)
    case int(value: Int)
    case bool(value: Bool)
}

protocol TokenValue {
    func equals(to value: TokenValue) -> Bool
}

extension TokenValue {
    
    func equals(to value: TokenValue) -> Bool {
        switch (self, value) {
        case (let a as Identifier, let b as Identifier): return a.value == b.value
        case (let a as Punctuator, let b as Punctuator): return a.value == b.value
        case (let a as Directive, let b as Directive): return a.value == b.value
        case (let a as Operator, let b as Operator): return a.value == b.value
        case (let a as Comment, let b as Comment): return a.value == b.value
        case (let a as Separator, let b as Separator): return a.value == b.value
        case (let a as TokenLiteral, let b as TokenLiteral): return a.value == b.value
        case (let a as Keyword, let b as Keyword): return a == b
        default: break
        }
        return false
    }
}

enum Keyword: String, CaseIterable, Equatable, TokenValue {
    case `func`
    case `break`
    case `continue`
    case `while`
    case `for`
    case `enum`
    case `struct`
    case `defer`
    case `if`
    case `else`
    case `switch`
    case `case`
    
    static let all = allCases.map(\.rawValue)
}

protocol StringValueToken: TokenValue { var value: String { get }}
struct Identifier: TokenValue, StringValueToken { let value: String }
struct Punctuator: TokenValue, StringValueToken { let value: String }
struct Directive: TokenValue, StringValueToken { let value: String }
struct Operator: TokenValue, StringValueToken { let value: String }
struct Comment: TokenValue, StringValueToken{ let value: String }
struct Separator: TokenValue, StringValueToken { let value: String }
struct TokenLiteral: TokenValue { let value: LiteralToken }

class Token: Equatable, CustomDebugStringConvertible {
    
    var debugDescription: String {
        if let string = value as? StringValueToken {
            return "Token [\(string.self)] \(string.value)"
        }
        else if let literal = value as? TokenLiteral {
            switch literal.value {
            case .string(let value): return "Token [Literal] '\(value)'"
            case .float(let value): return "Token [Literal] '\(value)'"
            case .int(let value): return "Token [Literal] '\(value)'"
            case .bool(let value): return "Token [Literal] '\(value)'"
            }
        }
        else if let keyword = value as? Keyword {
            return "Token [Keyword] '\(keyword.rawValue)'"
        }
        else { return "Token \(value)" }
    }
    
    let startCursor: Cursor
    let endCursor: Cursor
    let value: TokenValue
    
    init(_ value: TokenValue, start: Cursor = Cursor(), end: Cursor = Cursor()) {
        self.value = value
        self.startCursor = start
        self.endCursor = end
    }
    
    static func == (lhs: Token, rhs: Token) -> Bool {
        // this is for cursor tests
        if rhs.startCursor != rhs.endCursor {
            
            return lhs.startCursor == rhs.startCursor
                && lhs.endCursor == rhs.endCursor
                && lhs.value.equals(to: rhs.value)
        }
        return lhs.value.equals(to: rhs.value)
    }
}

struct LexerError: Error {
    
    enum Message: String, Equatable {
        
        // @Todo: improve these, turn them into functions?
        // I should be able to add information from the context.
        // For example: "Unexpected character `¿`."
        
        case unexpectedMinusInNumberLiteral = "Unexpected `-` in the middle of a number literal."
        case unexpectedDotInFloatLiteral = "Only a single `.` is expected in a float literal."
        case unexpectedEInFloatLiteral = "Only a single `e` is expected in a float literal."
        case newLineInStringLiteral = "String literal is not terminated before a new line"
        case unexpectedEndOfFile = "Unexpected end of file"
        case newlineExpectedBeforeMultilineStringLiteral = "Multiline string literal is expected to start from a new line."
        case newlineExpectedAfterMultilineStringLiteral = "Multiline string literal is expected to end after a new line."
        case emptyDirectiveName = "Directive identifier is expected after #."
        case unexpectedDirectiveName = "Unexpected characters in a directive identifier after #."
        case unexpectedCharacter = "Unexpected character."
    }
    
    let fileName: String?
    let cursor: Cursor
    let message: Message
    
    init(_ message: Message) {
        self.cursor = Cursor()
        self.message = message
        self.fileName = nil
    }
    
    init(fileName: String? = nil, cursor: Cursor, _ message: Message) {
        self.message = message
        self.cursor = cursor
        self.fileName = fileName
    }
}
