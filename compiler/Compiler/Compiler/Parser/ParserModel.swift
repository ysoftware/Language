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
        
        // common
        case expectedSemicolon = "Expected ';'."
        case declarationConflict = "Declaration conflicts with another declaration with the same name."
        
        // var decl
        case varDeclExpectedEquals = "Expected '=' or ':' for the variable or constant declaration."
        case varDeclTypeMismatch = "Type supplied does not match the type of expression."
        case varDeclRequiresType = "Variable declaration without expression requires type to be specified."
        
        // if
        case ifExpectedClosingParenthesis = "Closing parenthesis is expected after condition expression."
        case ifExpectedBrackets = "Expected brackets around if-else blocks."
        
        // procedure call
        case callExpectedClosingParenthesis = "Closing parenthesis is expected after arguments."
        case callNotProcedure = "Trying to call something that's not a procedure."
        case callArgumentsCount = "Procedure requires different number of arguments."
        case callArgumentTypeMismatch = "Argument expression doesn't match the type declared in the procedure."

        // procedure declaration
        case procNestedNotSupported = "Nested procedure declarations are not supported."
        case procArgumentParenthesis = "Expected parenthesis around arguments declaration."
        case procForeignUnexpectedBody = "Foreign procedure can not declare a body."
        case procExpectedBody = "Procedure is expected to have a body."
        case procExpectedArgumentType = "Expected a type of an argument after colon."
        case procExpectedArgumentName = "Expected argument name."
        case procExpectedArgumentBeforeVarargs = "Variadic argument requires definition before '...'."
        case procUndeclaredDirective = "Undeclared procedure directive."
        case procReturnTypeExpected = "Expected a return type after '->'."
        case procExpectedName = "Expected procedure name after 'func'."
        
        // struct declaration
        case structExpectedName = "Expected struct name after 'struct'."
        case structExpectedBrackets = "Expected brackets for structure declaration."
        case structExpectedBracketsEnd = "Expected brackets after structure members."
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
