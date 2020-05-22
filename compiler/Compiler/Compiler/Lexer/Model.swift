//
//  Model.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

//  identifier      x, color, UP
//  keyword         if, while, return, func
//  punctuator      }, (, ;, :
//  operator        +, <, =
//  literal         true, 6.02e23, "music"
//  comment         /* Retrieves user data */, // must be negative

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
        case (.identifier(let v), .identifier(let v2)): return v == v2
        case (.keyword(let v), .keyword(let v2)): return v == v2
        case (.punctuator(let v), .punctuator(let v2)): return v == v2
        case (.`operator`(let v), .`operator`(let v2)): return v == v2
        case (.comment(let v), .comment(let v2)): return v == v2
        case (.separator(let v), .separator(let v2)): return v == v2
        default: return false
        }
    }
    
    case identifier(name: String)
    case keyword(name: String)
    case punctuator(character: String)
    case `operator`(name: String)
    case literal(value: LiteralToken)
    case comment(text: String)
    case separator(symbol: String)
}

struct LexerError: Error {
    
    let lineNumber: Int
    let character: Int
    let message: String
    let filename: String
    
    init(_ message: String) {
        lineNumber = 0
        character = 0
        filename = "<no file>"
        self.message = message
    }
    
    init(filename: String, lineNumber: Int, character: Int, _ message: String) {
        self.lineNumber = lineNumber
        self.character = character
        self.message = message
        self.filename = filename
    }
}
