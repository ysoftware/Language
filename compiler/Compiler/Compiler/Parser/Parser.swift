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
    
    func matchVarDecl() -> Bool {
        token.value is Identifier
            && (peekNext()?.value as? Punctuator)?.value == ":"
            && (peekNext()?.value is Identifier
                || (peekNext()?.value as? Punctuator)?.value == "="
                || (peekNext()?.value as? Punctuator)?.value == ":")
    }
    
    func doVarDecl() -> Result<VariableDeclaration, ParserError> {
        guard let identifier = consumeIdent() else { assert(false) }
        assert(consumePunct(":"))
        
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let suppliedTypeName = consumeIdent()?.1.value
        var expectingExpression = true
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            if let error = doExpression().then({ expr = $0 }) { return .failure(error) }
            if let declaredType = suppliedTypeName, let exprType = expr?.expType.name,
                declaredType != exprType { return error(.varDeclTypeMismatch) }
        }
        guard consumeSep(";") else { return error(.expectedSemicolon) }
        // variable type inference
        let type: Type
        if let t = expr?.expType { type = t }
        else if let name = suppliedTypeName {
            // @Todo: refactor to "getType(...) -> Type"
            // that will resolve type depending on the currently known set of types
            if Type.isPrimitive(name) { type = .type(name: name) }
            else { type = .unresolved(name: name) }
        }
        else { return error(.varDeclRequiresType) }
        
        let varDecl = VariableDeclaration(
            name: identifier.value.value, expType: type, flags: flags, expression: expr)
        if case .resolved = type { dependOnGlobal(type.name, varDecl) }
        if let e = verifyNameConflict(varDecl) { return error(e) }
        // @Todo: add this var decl to local or global scope
        return .success(varDecl)
    }
    
    // MARK: - STRUCT DECLARATION -
    
    func doStructDecl() -> Result<StructDeclaration, ParserError> {
        assert(consumeKeyword(.struct))
        guard let name = consumeIdent()?.value else { return error(.structExpectedName) }
        guard consumePunct("{") else { return error(.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        while tokens.count > i {
            var member: VariableDeclaration?
            if matchVarDecl() {
                if let error = doVarDecl().then({ member = $0 }) { return .failure(error) }
                members.append(member!)
            }
            else {
                if consumePunct("}") { break }
                else { return error(.structExpectedBracketsEnd) }
            }
        }
        
        let structDecl = StructDeclaration(name: name.value, members: members)
        if let e = verifyNameConflict(structDecl) { return error(e) }
        declareGlobal(structDecl)
        return .success(structDecl)
    }
    
    // MARK: - PROCEDURE DECLARATION -
    
    func doProcDecl() -> Result<ProcedureDeclaration, ParserError> {
        assert(consumeKeyword(.func))
        guard let procName = consumeIdent()?.value else { return error(.procExpectedName) }
        guard consumePunct("(") else { return error(.procArgumentParenthesis) }
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
                guard token.value is Identifier else { return error(.procExpectedArgumentName) }
                guard let _ = consumeIdent()?.value, consumePunct(":"),
                    let argType = consumeIdent()?.value
                    else { return error(.procExpectedArgumentType) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(.type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { return error(.procArgumentParenthesis) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = .type(name: type.value) }
            else { return error(.procReturnTypeExpected) }
        }
        else { returnType = .void }
        if let directive = consume(Directive.self)?.value {
            if directive.value == "foreign" { flags.insert(.isForeign) }
            else { return error(.procUndeclaredDirective) }
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { return error(.procForeignUnexpectedBody) }
            if let error = doStatements().then({ scope = Scope(code: $0) }) { return .failure(error) }
        }
        else {
            return error(.procExpectedBody)
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        if let e = verifyNameConflict(procedure) { return error(e) }
        declareGlobal(procedure)
        return .success(procedure)
    }
    
    // MARK: - IF-ELSE -
    
    func doIf() -> Result<Condition, ParserError> {
        assert(consumeKeyword(.if))
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
        guard consumePunct("}") else { return error(.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(.ifExpectedBrackets) }
            if let error = doStatements().then({ elseBody = $0 }) { return .failure(error) }
            guard consumePunct("}") else { return error(.ifExpectedBrackets) }
        }
        return .success(Condition(
            condition: condition, block: Scope(code: ifBody), elseBlock: Scope(code: elseBody)))
    }
    
    // MARK: - EXPRESSIONS -
    
    func doExpression() -> Result<Expression, ParserError> {
        defer { nextToken() }
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
        default: break
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
                    return .success(statements)
                }
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                if keyword == .func {
                    return error(.procNestedNotSupported)
                }
                else if keyword == .if {
                    if let error = doIf().then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                else {
                    print("Unexpected keyword: \(keyword.rawValue)")
                    return error(.notImplemented)
                }
            case is Identifier: // @Clean: this is a copy from the main loop
                if matchVarDecl() {
                    if let error = doVarDecl().then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                else {
                    print("(statements loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                    return error(.notImplemented)
                }
            default:
                print("(statements loop) Unexpected token\n\(token)\n")
                return error(.notImplemented)
            }
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
        
        loop: while tokens.count > i {
            switch token.value  {
            case let keyword as Keyword:
                if keyword == .func {
                    if let error = doProcDecl().then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                    
                if keyword == .struct {
                    if let error = doStructDecl().then({ statements.append($0) }) { return .failure(error)}
                    break
                }
                    
                else {
                    print("Keyword \(keyword.rawValue) is not YET implemented.")
                    return error(.notImplemented)
                }
                    
                    
            case is Identifier:
                if matchVarDecl() {
                    if let error = doVarDecl().then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                    
                else {
                    print("(main loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                    return error(.notImplemented)
                }
                
            default: if !nextToken() { break loop }
            }
        }
        return .success(Scope(code: statements))
    }
}
