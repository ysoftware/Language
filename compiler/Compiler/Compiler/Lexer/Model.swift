//
//  Model.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let keywords = [
    "func",
    "break",
    "continue",
    "while",
    "for",
    "enum",
    "struct",
    "defer"
]

enum LiteralToken: Equatable {
    
    static func == (lhs: LiteralToken, rhs: LiteralToken) -> Bool {
        switch (lhs, rhs) {
        case (.string(let v), .string(let v2)): return v == v2
        case (.float(let v), .float(let v2)): return v == v2
        case (.int(let v), .int(let v2)): return v == v2
        default: return false
        }
    }
    
    case string(value: String)
    case float(value: Float)
    case int(value: Int)
}

enum Token: Equatable {
    
    static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.literal(let v), .literal(let v2)): return v == v2
        case (.directive(let v), .directive(let v2)): return v == v2
        case (.identifier(let v), .identifier(let v2)): return v == v2
        case (.keyword(let v), .keyword(let v2)): return v == v2
        case (.punctuator(let v), .punctuator(let v2)): return v == v2
        case (.`operator`(let v), .`operator`(let v2)): return v == v2
        case (.comment(let v), .comment(let v2)): return v == v2
        case (.separator(let v), .separator(let v2)): return v == v2
        default: return false
        }
    }
    
    case identifier(value: String)
    case keyword(value: String)
    case punctuator(value: String)
    case directive(value: String)
    case `operator`(value: String)
    case literal(value: LiteralToken)
    case comment(value: String)
    case separator(value: String)
}

struct LexerError: Error {
    
    enum Message: String, Equatable {
        
        case unexpectedDotInFloatLiteral = "Only a single `.` is expected in a float literal."
        case unexpectedEInFloatLiteral = "Only a single `e` is expected in a float literal."
        case newLineInStringLiteral = "String literal is not terminated before a new line"
        case newlineExpectedBeforeMultilineStringLiteral = "Multiline string literal is expected to start from a new line."
        case newlineExpectedAfterMultilineStringLiteral = "Multiline string literal is expected to end after a new line."
        case emptyDirectiveName = "Directive identifier is expected after #."
        case unexpectedDirectiveName = "Unexpected characters in a directive identifier after #."
    }
    
    let lineNumber: Int
    let character: Int
    let message: Message
    let filename: String
    
    init(_ message: Message) {
        lineNumber = 0
        character = 0
        filename = "<no file>"
        self.message = message
    }
    
    init(filename: String, lineNumber: Int, character: Int, _ message: Message) {
        self.message = message
        self.lineNumber = lineNumber
        self.character = character
        self.filename = filename
    }
}
