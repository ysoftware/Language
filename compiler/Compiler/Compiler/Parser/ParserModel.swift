//
//  ParserModel.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 24.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct ParserError: Error {
    
    let fileName: String?
    let startCursor: Cursor
    let endCursor: Cursor
    let message: String
    
    init(_ message: String) {
        self.startCursor = Cursor()
        self.endCursor = Cursor()
        self.message = message
        self.fileName = nil
    }
    
    init(fileName: String? = nil, startCursor: Cursor, endCursor: Cursor, _ message: String) {
        self.message = message
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.fileName = fileName
    }
}

class Context { }

class ContextLoop: Context {
    internal init(label: String?) { self.label = label }
    let label: String?
}

class Scope {
    
    var declarations: [String: Ast]
    var contexts: [Context] = []
    
    func next(as context: Context? = nil) -> Scope {
        let newScope = Scope(declarations: declarations, contexts: contexts)
        context.map { newScope.contexts.append($0) }
        return newScope
    }
    
    internal init(declarations: [String : Ast] = [:], contexts: [Context] = []) {
        self.declarations = declarations
        self.contexts = contexts
    }
}

extension Parser {
    
    class ErrorMessage {
        weak var p: Parser!
        
        // common
        var notImplemented: String { "Not implemented: \(p.token)" }
        let expectedSemicolon = "Expected ';' after an expression."
        let expectedParenthesis = "Parenthesis are expected around the condition expression."
        
        func declarationConflict(_ d: Ast) -> String {
            // @Todo point to definition by cursor
            "Declaration conflicts with another declaration with the same name: \(d)"
        }
        
        // var assign
        func assignPassedNotValue(_ s: Ast) -> String { "Expression is not a value: \(s)." }
        
        // var decl
        let varDeclExpectedEquals = "Expected '=' or ':' for the variable or constant declaration."
        let varDeclTypeMismatch = "Type supplied does not match the type of expression."
        let varDeclRequiresType = "Variable declaration without expression requires type to be specified."
        
        // if
        let ifExpectedBrackets = "Expected brackets around if-else blocks."
        let ifNotExpectedAtGlobalScope = "If statement is not expected at the global scope"
        
        // loop
        let loopNotExpectedAtGlobalScope = "While statement is not expected at the global scope"
        let loopExpectedClosingParenthesis = "Closing parenthesis is expected around the condition expression."
        let loopExpectedBrackets = "Expected brackets around a loop body."
        let loopLabelDuplicate = "Break with this label is already declared in the current scope."
        
        // break
        let breakContext = "Break can't be used outside of loop or switch."
        let breakLabelNotFound = "Loop with this label is not found in the current scope."

        // procedure call
        let callExpectedClosingParenthesis = "Closing parenthesis is expected after arguments."
        let callNotProcedure = "Trying to call something that's not a procedure."
        let callArgumentsCount = "Procedure requires different number of arguments."
        let callArgumentTypeMismatch = "Argument expression doesn't match the type declared in the procedure."
        
        // procedure declaration
        let procNestedNotSupported = "Nested procedure declarations are not supported."
        let procArgumentParenthesis = "Expected parenthesis around arguments declaration."
        let procForeignUnexpectedBody = "Foreign procedure can not declare a body."
        let procExpectedBody = "Procedure is expected to have a body."
        let procExpectedArgumentType = "Expected a type of an argument after colon."
        let procExpectedArgumentName = "Expected argument name."
        let procExpectedArgumentBeforeVarargs = "Variadic argument requires definition before '...'."
        let procUndeclaredDirective = "Undeclared procedure directive."
        let procReturnTypeExpected = "Expected a return type after '->'."
        let procExpectedName = "Expected procedure name after 'func'."
        
        // struct declaration
        let structExpectedName = "Expected struct name after 'struct'."
        let structExpectedBrackets = "Expected brackets for structure declaration."
        let structExpectedBracketsEnd = "Expected brackets after structure members."
    }
}
