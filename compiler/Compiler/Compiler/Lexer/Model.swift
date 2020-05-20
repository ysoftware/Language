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

enum LiteralToken {
    
    case string(value: String)
    case float(value: Float)
    case int(value: Int)
}

enum Token {
    
    case identifier(name: String)
    case keyword(name: String)
    case punctuator(character: String)
    case `operator`(name: String)
    case literal(value: LiteralToken)
    case comment(text: String)
    case separator(symbol: String)
}
