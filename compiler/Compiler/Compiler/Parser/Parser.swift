//
//  Parser.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

extension Parser {
    
    // MARK: - VARIABLE DECLARATION -
    
    func doVarDecl(_ identifier: Identifier) -> Result<VariableDeclaration, ParserError> {
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let suppliedTypeName = consumeIdent()?.1.value
        var expectingExpression = true
        if consumeOp("=") { /* not a constant */ }
        else if consumePunct(":") { flags.insert(.isConstant) }
        else { expectingExpression = false }
        
        if expectingExpression {
            if let error = doExpression().then({ expr = $0 }) { return .failure(error) }
            if let declaredType = suppliedTypeName, let exprType = expr?.expType.name,
                declaredType != exprType { return error(.varDeclTypeMismatch) }
        }
        guard consumeSep(";") else { return error(.expectedSemicolon) }
        let type: Type
        if let t = expr?.expType { type = t }
        else if let name = suppliedTypeName {
            if Type.isPrimitive(name) { type = .type(name: name) }
            else { type = .unresolved(name: name) }
        }
        else { return error(.varDeclRequiresType) }
        
        let varDecl = VariableDeclaration(
            id: identifier.value, expType: type, flags: flags, expression: expr)
        if case .resolved = type { dependOnGlobal(type.name, varDecl) }
        // @Todo: add this var decl to local or global scope
        return .success(varDecl)
    }
    
    // MARK: - PROCEDURE DECLARATION -
    
    func doProcDecl() -> Result<ProcedureDeclaration, ParserError> {
        guard let procName = consumeIdent()?.value else { return error(.procExpectedName) }
        guard consumePunct("(") else { return error(.procExpectedBrackets) }
        let returnType: Type
        let name = procName.value
        let id = "global_func_\(procName.value)" // @Todo: don't change the name of 'main'? or create a #main directive
        var arguments: [Type] = []
        var flags = ProcedureDeclaration.Flags()
        var scope: Scope = .empty
        while tokens.count > i { // PROCEDURE ARGUMENTS
            if consumePunct("...") {
                if arguments.isEmpty { return error(.procExpectedArgumentBeforeVarargs) }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard peekNext()?.value is Identifier else { return error(.procExpectedArgumentName) }
                guard let _ = consumeIdent()?.value, consumePunct(":"),
                    let argType = consumeIdent()?.value
                    else { return error(.procExpectedArgumentType) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(.type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { return error(.procExpectedBrackets) }
        if consumePunct("->") {
            if let type = consumeNext(Identifier.self)?.value { returnType = .type(name: type.value) }
            else { return error(.procReturnTypeExpected) }
        }
        else { returnType = .void }
        if let directive = consumeNext(Directive.self)?.value {
            if directive.value == "foreign" { flags.insert(.isForeign) }
            else { return error(.procUndeclaredDirective) }
        }
        if consumePunct("{") {
            if flags.contains(.isForeign) { return error(.procForeignUnexpectedBody) }
            if let error = doStatements().then({ scope = Scope(code: $0) }) { return .failure(error) }
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        declareGlobal(procedure)
        return .success(procedure)
    }
    
    // MARK: - IF-ELSE -
    
    func doIf() -> Result<Condition, ParserError> {
        let hasParenthesis = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        if hasParenthesis {
            if let error = doExpression().then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(.ifExpectedClosingParenthesis) }
        }
        if !consumePunct("{") { return error(.ifExpectedBrackets) }
        if let error = doStatements().then({ ifBody = $0 }) { return .failure(error) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(.ifExpectedBrackets) }
            if let error = doStatements().then({ elseBody = $0 }) { return .failure(error) }
        }
        return .success(Condition(
            condition: condition, block: Scope(code: ifBody), elseBlock: Scope(code: elseBody)))
    }
    
    // MARK: - EXPRESSIONS -
    
    func doExpression() -> Result<Expression, ParserError> {
        while tokens.count > i {
            switch token.value {
            case let literal as TokenLiteral:
                switch literal.value {
                case .int(let value): return .success(IntLiteral(value: value))
                case .bool(let value): return .success(BoolLiteral(value: value))
                case .float(let value): return .success(FloatLiteral(value: value))
                case .string(let value): return .success(StringLiteral(value: value))
                }
            case let identifier as Identifier:
                let value = Value(name: identifier.value, expType: .predicted(.bool))
                dependOnGlobal(identifier.value, value)
                return .success(value)
            // @Todo: more expressions
            default: break
            }
            nextToken()
        }
        return error(.notImplemented)
    }
    
    // MARK: - STATEMENTS -
    
    func doStatements() -> Result<[Statement], ParserError> {
        // body of: procedure, if-else, loop
        var statements: [Statement] = []
        while tokens.count > i {
            switch token.value  {
            case let punct as Punctuator:
                if punct.value == "}" { // done with the scope
                    nextToken()
                    return .success(statements)
                }
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                if keyword == .func { return error(.procNestedNotSupported) }
                if keyword == .if {
                    if let error = doIf().then({ statements.append($0) }) { return .failure(error) }
                }
            case let identifier as Identifier: // @Clean: this is a copy from the main loop
                if consumePunct(":"),
                    let error = doVarDecl(identifier).then({ statements.append($0) }) { return .failure(error) }
            default: break
            }
            nextToken()
        }
        return .success(statements)
    }
}

// MARK: - Parser

class Parser {
    
    init(fileName: String? = nil, _ tokens: [Token]) {
        self.fileName = fileName
        self.tokens = tokens
        self.token = tokens[i]
    }
    
    let fileName: String?
    let tokens: [Token]
    
    // Variables
    
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var global_declarations: [String: Ast] = [:] /// all declarations in global scope
    var struct_declarations: [String: StructDeclaration] = [:] /// all structs declared
    var i = 0
    var token: Token
    var statements: [Statement] = []
    
    func parse() -> Result<Scope, ParserError> {
        
        // Cycle
        
        while tokens.count > i {
            switch token.value  {
            case let keyword as Keyword:
                if keyword == .func,
                    let error = doProcDecl().then({ statements.append($0) }) { return .failure(error) }
            case let identifier as Identifier:
                if consumePunct(":"),
                    let error = doVarDecl(identifier).then({ statements.append($0) }) { return .failure(error) }
            default: break
            }
            nextToken()
        }
        return .success(Scope(code: statements))
    }
}
