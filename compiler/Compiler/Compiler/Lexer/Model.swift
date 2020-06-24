//
//  Model.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
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
    case float(value: Float64)
    case int(value: Int)
    case bool(value: Bool)
    case null
    case void
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
        case (is EOF, is EOF): return true
        default: break
        }
        return false
    }
}

enum Keyword: String, CaseIterable, Equatable, TokenValue {
    case `func`
    case `break`
    case `continue`
    case `fallthrough`
    case `while`
    case `for`
    case `enum`
    case `struct`
    case `defer`
    case `if`
    case `else`
    case `switch`
    case `case`
    case `return`
    case sizeof
    
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
struct EOF: TokenValue { }

final class Token: Equatable, CustomDebugStringConvertible {
    
    var tokenType: String {
        switch value {
        case is Identifier: return "Identifier"
        case is Punctuator: return "Punctuator"
        case is Directive: return "Directive"
        case is Operator: return "Operator"
        case is Comment: return "Comment"
        case is Separator: return "Separator"
        case is EOF: return "End."
        default: return "\(self.self)"
        }
    }
    
    var debugDescription: String {
        if let string = value as? StringValueToken {
            return "[\(tokenType)] \"\(string.value)\" (\(startCursor)-\(endCursor))"
        }
        else if let literal = value as? TokenLiteral {
            switch literal.value {
            case .string(let value): return "[Literal] '\(value.reescaped)' (\(startCursor)-\(endCursor))"
            case .float(let value): return "[Literal] '\(value)' (\(startCursor)-\(endCursor))"
            case .int(let value): return "[Literal] '\(value)' (\(startCursor)-\(endCursor))"
            case .bool(let value): return "[Literal] '\(value)' (\(startCursor)-\(endCursor))"
            case .void: return "[Void]"
            case .null: return "[Null]"
            }
        }
        else if let keyword = value as? Keyword {
            return "[Keyword] '\(keyword.rawValue)' (\(startCursor)-\(endCursor))"
        }
        else { return "Token \(value) (\(startCursor)-\(endCursor))" }
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
        
        case unexpectedMinusInNumberLiteral = "Unexpected '-' in the middle of a number literal."
        case unexpectedDotInFloatLiteral = "Only a single '.' is expected in a float literal."
        case unexpectedEInFloatLiteral = "Only a single 'e' is expected in a float literal."
        case newLineInStringLiteral = "String literal is not terminated before a new line."
        case unexpectedEndOfFile = "Unexpected end of file."
        case unexpectedCharacterToEscape = "Unexpected character to escape in a string literal."
        case newlineExpectedBeforeMultilineStringLiteral = "Multiline string literal is expected to start from a new line."
        case newlineExpectedAfterMultilineStringLiteral = "Multiline string literal is expected to end after a new line."
        case emptyDirectiveName = "Directive identifier is expected after #."
        case unexpectedDirectiveName = "Unexpected characters in a directive identifier after #."
        case unexpectedCharacter = "Unexpected character."
        case invalidIdentifierUnderscore = "'_' is not a valid identifier."
    }

    let fileName: String?
    let startCursor: Cursor
    let endCursor: Cursor
    let message: Message
    
    init(_ message: Message) {
        self.startCursor = Cursor()
        self.endCursor = Cursor()
        self.message = message
        self.fileName = nil
    }
    
    init(fileName: String? = nil, startCursor: Cursor, endCursor: Cursor, _ message: Message) {
        self.message = message
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.fileName = fileName
    }
}
