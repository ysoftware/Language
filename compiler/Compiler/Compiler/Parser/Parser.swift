//
//  Parser.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

func parse(fileName: String? = nil, _ tokens: [Token]) -> Result<Scope, ParserError> {
    
    // Variables
    
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var global_declarations: [String: Ast] = [:] /// all declarations in global scope
    var struct_declarations: [String: StructDeclaration] = [:] /// all structs declared
    var i = 0
    var token = tokens[i]
    var statements: [Statement] = []
    
    // Methods
    
    // @Todo: add append method the same as in Lexer
    // to auto-include the Cursor in the Ast
    
    func dependOnGlobal(_ dependency: String, _ statement: Ast) {
        if unresolved[dependency] == nil { unresolved[dependency] = [] }
        unresolved[dependency]!.append(statement)
    }
    
    func declareGlobal(_ declaration: Ast) {
        let name: String
        if let proc = declaration as? ProcedureDeclaration { name = proc.name }
        else if let variable = declaration as? VariableDeclaration { name = variable.id }
        else { fatalError("Only variables and procedures can be declared at global scope") }
        global_declarations[name] = declaration
    }
    
    /// returns the error set at the current point
    func error<T>(_ error: ParserError.Message) -> Result<T, ParserError> {
        .failure(ParserError(fileName: fileName, cursor: token.endCursor, error))
    }
    
    /// advances the counter
    func advance(_ count: Int = 1) {
        i += count
    }
    
    /// advances the counter and sets `token` to the next in the array
    @discardableResult
    func nextToken() -> Bool {
        advance()
        guard tokens.count > i else { return false }
        token = tokens[i]
        return true
    }
    
    /// Peeks at the `next` token
    func peekNext() -> Token? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        return tokens[nextIndex]
    }
    
    /// checks if `next token's value` is of the type passed, then eats if if it does
    /// if not, does nothing and returns nil
    func consumeNext<T: TokenValue>(_ value: T.Type) -> (Token, T)? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        token = tokens[nextIndex]
        if let value = token.value as? T {
            advance()
            return (token, value)
        }
        return nil
    }
    
    /// checks if `next char` exists and matches the predicate, then eats it if it does
    /// if not, does nothing and returns nil
    func consumeNext(where compare: (TokenValue)->Bool) -> Token? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        token = tokens[nextIndex]
        if compare(token.value) {
            advance()
            return token
        }
        return nil
    }
    
    /// checks if `next char` exists, is a string-value token, and matches the passed value, then eats it if it does
    /// if not, does nothing and returns `false`
    func consumeNext<T: StringValueToken>(_ type: T.Type, matching value: String) -> Bool {
        return consumeNext(where: { ($0 as? T)?.value == value }) != nil
    }
    
    func consumeKeyword(_ keyword: Keyword) -> Bool {
        consumeNext(where: { ($0 as? Keyword) == .else }) != nil
    }
    
    func consumePunct(_ value: String) -> Bool { consumeNext(Punctuator.self, matching: value) }
    func consumeSep(_ value: String) -> Bool { consumeNext(Separator.self, matching: value) }
    func consumeOp(_ value: String) -> Bool { consumeNext(Operator.self, matching: value) }
    func consumeIdent() -> (Token, Identifier)? { consumeNext(Identifier.self) }

    func doProcDecl() -> Result<ProcedureDeclaration, ParserError> {
        guard let (_, procName) = consumeIdent() else { return error(.procExpectedName) }
        guard consumePunct("(") else { return error(.procExpectedBrackets) }
        
        let returnType: Type
        let name = procName.value
        let id = "global_func_\(procName.value)"
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
                
                guard let (_, argName) = consumeIdent(), consumePunct(":"),
                    let (_, argType) = consumeIdent()
                    else { return error(.procExpectedArgumentType) }
                
                _ = argName // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(.type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        
        if !consumePunct(")") { return error(.procExpectedBrackets) }
        
        if consumePunct("->") {
            if let (_, type) = consumeNext(Identifier.self) { returnType = .type(name: type.value) }
            else { return error(.procReturnTypeExpected) }
        }
        else { returnType = .void }
        
        // directives
        if let (_, directive) = consumeNext(Directive.self) {
            if directive.value == "foreign" { flags.insert(.isForeign) }
            else { return error(.procUndeclaredDirective) }
        }
        
        // procedure body
        if consumePunct("{") {
            if flags.contains(.isForeign) { return error(.procForeignUnexpectedBody) }
            
            // parse scope until matching "}"
            if let error = doStatements().then({ scope = Scope(code: $0) }) { return .failure(error) }
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        declareGlobal(procedure)
        return .success(procedure)
    }
    
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
    
    // body of: procedure, if-else, loop
    func doStatements() -> Result<[Statement], ParserError> {
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
    
    // Cycle
    
    while tokens.count > i {
        switch token.value  {
        
        case let keyword as Keyword:
            
            // PROCEDURE DECLARATION
            if keyword == .func,
                let error = doProcDecl().then({ statements.append($0) }) { return .failure(error) }
            
        case let identifier as Identifier:
            
            // VARIABLE DECLARATION
            if consumePunct(":"),
                let error = doVarDecl(identifier).then({ statements.append($0) }) { return .failure(error) }
            
            
        default:
            break
        }
        nextToken()
    }
    return .success(Scope(code: statements))
}
