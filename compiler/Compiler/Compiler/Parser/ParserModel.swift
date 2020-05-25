//
//  ParserModel.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 24.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct ParserError: Error {
    
    enum Message: String, Equatable {
        
        case notImplemented = "Not implemented"
        
        // procedure declaration
        case procExpectedBrace = "Expected an opening or closing parenthesis."
        case procForeignUnexpectedBody = "Foreign procedure can not declare a body."
        case procExpectedArgumentType = "Expected a type of an argument after `:`."
        case procExpectedArgumentName = "Expected argument name."
        case procExpectedArgumentBeforeVarargs = "Variadic argument requires definition before `...`."
        case procUndeclaredDirective = "Undeclared procedure directive."
        case procReturnTypeExpected = "Expected a return type after `->`."
        case procExpectedName = "Expected procedure name after `func`."
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
