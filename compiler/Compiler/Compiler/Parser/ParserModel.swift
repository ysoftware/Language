//
//  ParserModel.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 24.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct ParserError: Error, Equatable {
    
    let fileName: String?
    let startCursor: Cursor
    let endCursor: Cursor
    let message: String
    var context: String?
    
    init(fileName: String? = nil, startCursor: Cursor, endCursor: Cursor,
         message: String, context: String? = nil) {
        self.message = message
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.fileName = fileName
        self.context = context
    }
    
    static func ==(lhs: ParserError, rhs: ParserError) -> Bool {
        lhs.startCursor == rhs.startCursor && lhs.endCursor == rhs.endCursor && lhs.message == rhs.message
    }
}

class Context { }

final class ContextLoop: Context {
    internal init(label: String?) { self.label = label }
    let label: String?
}

final class Scope {
    
    static let globalId = "global_"
    static let unresolvedId = "UNRESOLVED"

    var id: String
    var declarations: [String: Declaration]
    var contexts: [Context] = []
    
    internal init(declarations: [String : Declaration] = [:], id: String, contexts: [Context] = []) {
        self.id = id
        self.declarations = declarations
        self.contexts = contexts
    }
}

extension Parser {
    
    final class ErrorMessage {
        weak var p: Parser!
        
        // common
        let unexpectedEndOfFile = "Unexpected end of file."
        var notImplemented: String { "Token not implemented: '\(p.token)'." }
        let expectedSemicolon = "Expected ';' after an expression."
        let expectedExpression = "Expected expression."
        let expectedParentheses = "Parentheses are expected around the condition expression."
        let exprExpectedBrackets = "Expected closing bracket after expression."
        func unexpectedToken(_ t: String) -> String { "Unexpected token: '\(t)'." }

        func returnTypeNotMatching(_ e: Type, _ g: Type) -> String {
            "Return type is expected to be '\(e)', but expression provided evaluates to '\(g)'."
        }
        
        // other
        func conditionTypeMismatch(_ t: Type) -> String { "Condition is expected to be of type 'Bool', '\(t.typeName)' was given." }
        let sizeofExpectedType = "Type name is expected after 'sizeof'."
        let castExpectsTypeInBrackets = "Expected type in round brackets after 'cast'."
        let newExpectsTypeIdent = "Expected type identifier after 'new'."
        let freeExpectsPointer = "Expected expression of pointer type after 'free'."

        // member access
        func memberAccessNonStruct(_ t: Type) -> String {
            "Trying to perform member access on a non-struct value of '\(t)'"
        }
        
        // operation
        func binopArgTypeMatch(_ l: Type, r: Type) -> String {
            "Argument types don't match. Left is '\(l)', right is '\(r)'."
        }
        
        func binopArgTypeSupport(_ n: String, t: Type) -> String {
            "Operation \(n) doesn't support arguments of type '\(t)'."
        }
        
        func declarationConflict(_ d: Declaration) -> String {
            // @Todo point to definition by cursor
            "Declaration conflicts with another declaration with the same name on line \(d.startCursor.lineNumber)."
        }
        
        // var assign
        func assignPassedNotValue(_ s: Ast) -> String { "Expression is not a value: '\(s)'." }
        func assignUndeclared(_ n: String) -> String { "Undeclared variable '\(n)'." }
        func assignConst(_ n: String) -> String { "\(n) is declared as constant." }
        func assignTypeMismatch(_ e: Type, _ g: Type) -> String { "Variable is declared as \(e), but expression given evaluates to \(g)." }
        func assignNotRValue(_ n: String) -> String { "\(n) is not an rvalue." }

        // var decl
        func declTypeIsDeclaration() -> String { "Type specified matches to a declaration." }
        let varDeclExpectedEquals = "Expected '=' or ':' for the variable or constant declaration."
        func varDeclTypeMismatch(_ e: Type, _ g: Type) -> String { "Type supplied '\(g)' does not match the type '\(e)' as specified." }
        let varDeclRequiresType = "Variable declaration without expression requires type to be specified."
        
        let expectedMemberIdentifier = "Expected identifier after '.' for member access."
        let unexpectedMemberAccess = "Unexpected member access expression."

        // if
        let ifExpectedBrackets = "Expected brackets around if-else blocks."
        let ifNotExpectedAtGlobalScope = "If statement is not expected at the global scope"
        
        // loop
        let loopNotExpectedAtGlobalScope = "While statement is not expected at the global scope"
        let loopExpectedClosingParentheses = "Closing parentheses is expected around the condition expression."
        let loopExpectedBrackets = "Expected brackets around a loop body."
        let loopLabelDuplicate = "Break with this label is already declared in the current scope."
        let loopLabelNotFound = "Loop with this label is not found in the current scope."
        
        // break, continue
        let breakContext = "Break can't be used outside of loop or switch."
        let continueContext = "Continue can't be used outside of loop or switch."

        // procedure call
        let callExpectedClosingParentheses = "Closing parentheses is expected after arguments."
        let callNotProcedure = "Trying to call something that's not a procedure."
        func callArgumentsCount(_ r: Int, _ g: Int) -> String { "Procedure requires \(r) argument\(plural(r)), \(g) given." }
        func callArgumentsVarCount(_ r: Int, _ g: Int) -> String { "Procedure requires at least \(r) arguments, \(g) given." }
        
        func callArgumentTypeMismatch(_ e: String, _ g: String) -> String {
            "Argument of type '\(e)' is expected by the procedure, '\(g)' given."
        }
        
        // procedure declaration
        let procNestedNotSupported = "Nested procedure declarations are not supported."
        let procArgumentParentheses = "Expected parentheses around arguments declaration."
        let procForeignUnexpectedBody = "Foreign procedure can not declare a body."
        let procExpectedBody = "Procedure is expected to have a body."
        let procExpectedArgumentType = "Expected a type of an argument after colon."
        let procExpectedArgumentName = "Expected argument name."
        let procExpectedArgumentBeforeVarargs = "Variadic argument requires definition before '...'."
        let procUndeclaredDirective = "Undeclared procedure directive."
        let procMainRedecl = "Redeclaration of the entry procedure."
        let procReturnTypeExpected = "Expected a return type after '->'."
        func procExpectedName(_ g: Token) -> String { "Expected procedure name identifier after 'func'. Got \(g) instead." }
        let procNotReturning = "Expected a return statement in a non-void procedure."
        
        // struct declaration
        let structExpectedName = "Expected struct name after 'struct'."
        let structExpectedBrackets = "Expected brackets for structure declaration."
        let structExpectedBracketsEnd = "Expected brackets after structure members."
        let structExpectedClosingTriangleBracket = "Expected '>' after a list of types for a generic struct declaration."
        let structExpectedGenericType = "Expected type name for a generic struct declaration."
        func structExpectedGenericTypeIdent(_ g: Token) -> String { "Expected type name identifier. Got \(g) instead" }
    }
}
