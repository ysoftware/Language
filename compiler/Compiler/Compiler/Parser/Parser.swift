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
    
    func doVarDecl(in scope: Scope) -> Result<VariableDeclaration, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        guard let identifier = consumeIdent() else { assert(false) }
        assert(consumePunct(":"))
        
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let suppliedTypeName = consumeIdent()?.1.value
        var expectingExpression = true
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            if let error = doExpression(in: scope).then({ expr = $0 }) { return .failure(error) }
            if let declaredType = suppliedTypeName, let exprType = expr?.exprType.name {
                if let literal = expr as? LiteralExpr, literal.isCompliable(with: declaredType) {
                    literal.exprType = .resolved(name: declaredType)
                }
                else if declaredType != exprType { return error(em.varDeclTypeMismatch) }
            }
        }
        
        // variable type inference
        let type: Type
        if let t = expr?.exprType { type = t }
        else if let name = suppliedTypeName {
            // @Todo: refactor to "getType(...) -> Type"
            // that will resolve type depending on the currently known set of types
            if Type.isPrimitive(name) { type = .type(name: name) }
            else { type = .unresolved(name: name) }
        }
        else { return error(em.varDeclRequiresType) }
        
        let varDecl = VariableDeclaration(
            name: identifier.value.value, exprType: type, flags: flags, expression: expr)
        if case .resolved = type { appendUnresolved(type.name, varDecl) }
        if let e = verifyNameConflict(varDecl, in: scope) { return error(e) }
        appendDeclaration(varDecl, to: scope)
        if !consumeSep(";") { return error(em.expectedSemicolon) }
        return .success(varDecl)
    }
    
    // MARK: - STRUCT DECLARATION -
    
    func doStructDecl() -> Result<StructDeclaration, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        assert(consumeKeyword(.struct))
        guard let name = consumeIdent()?.value else { return error(em.structExpectedName) }
        guard consumePunct("{") else { return error(em.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        let structScope = globalScope.copy()
        while tokens.count > i {
            var member: VariableDeclaration?
            if matchVarDecl() {
                if let error = doVarDecl(in: structScope).then({ member = $0 }) { return .failure(error) }
                members.append(member!)
            }
            else {
                if consumePunct("}") { break }
                else { return error(em.structExpectedBracketsEnd) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, members: members)
        if let e = verifyNameConflict(structDecl) { return error(e) }
        appendDeclaration(structDecl, to: globalScope)
        return .success(structDecl)
    }
    
    // MARK: - PROCEDURE CALL -
    
    func matchProcedureCall() -> Bool {
        token.value is Identifier && (peekNext()?.value as? Punctuator)?.value == "("
    }
    
    func doProcedureCall(in scope: Scope) -> Result<ProcedureCall, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        guard let name = consumeIdent()?.value, consumePunct("(")
            else { fatalError("call matchProcedureCall required before calling this") }
        var arguments: [Expression] = []
        while tokens.count > i { // PROCEDURE CALL ARGUMENTS
            if (token.value as? Punctuator)?.value == ")" { break }
            if let error = doExpression(in: scope).then({ arguments.append($0) }) { return .failure(error) }
            if !consumeSep(",") { break }
        }
        guard consumePunct(")") else { return error(em.expectedParenthesis) }
        var returnType: Type = .unresolved(name: nil)
        if let statement = scope.declarations[name.value] { // else - proceed
            if let procDecl = statement as? ProcedureDeclaration {
                if case .resolved = procDecl.returnType { returnType = procDecl.returnType }
                guard arguments.count >= procDecl.arguments.count else { return error(em.callArgumentsCount) }
                for i in 0..<arguments.count {
                    guard procDecl.arguments.count > i || procDecl.flags.contains(.isVarargs)
                        else { return error(em.callArgumentsCount) }
                    let declArgument = procDecl.arguments.count > i ? procDecl.arguments[i] : procDecl.arguments.last!
                    switch arguments[i].exprType {
                        // @Todo: refactor to matching procedure. This should be recursive.
                    case .resolved(let name), .predicted(let name):
                        if name != declArgument.name { return error(em.callArgumentTypeMismatch) }
                    case .unresolved(let name):
                        // @Todo: match with structs if not primitive (the block inside if)
                        if let name = name { arguments[i].exprType = .type(name: name) }
                        else { arguments[i].exprType = .predicted(name: declArgument.name) }
                    }
                }
            }
            else { return error(em.callNotProcedure) }
        }
        // @Todo: match expressions to argument types
        
        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments)
        if case .resolved = returnType { appendUnresolved(returnType.name, call) }
        return .success(call)
    }
    
    // MARK: - PROCEDURE DECLARATION -
    
    func doProcDecl(in scope: Scope) -> Result<ProcedureDeclaration, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        assert(consumeKeyword(.func))
        guard let procName = consumeIdent()?.value else { return error(em.procExpectedName) }
        guard consumePunct("(") else { return error(em.expectedParenthesis) }
        let returnType: Type
        let name = procName.value
        let id = "__global_func_\(procName.value)" // @Todo: don't change the name of 'main'? or create a #main directive
        var arguments: [Type] = []
        var flags = ProcedureDeclaration.Flags()
        var scope: Code = .empty
        while tokens.count > i { // PROCEDURE ARGUMENTS DECLARATION
            if (token.value as? Punctuator)?.value == ")" { break }
            if consumePunct("...") {
                if arguments.isEmpty { return error(em.procExpectedArgumentBeforeVarargs) }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard token.value is Identifier else { return error(em.procExpectedArgumentName) }
                guard let _ = consumeIdent()?.value, consumePunct(":"),
                    let argType = consumeIdent()?.value
                    else { return error(em.procExpectedArgumentType) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(.type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { return error(em.procArgumentParenthesis) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = .type(name: type.value) }
            else { return error(em.procReturnTypeExpected) }
        }
        else { returnType = .void }
        if let directive = consume(Directive.self)?.value {
            if directive.value == "foreign" { flags.insert(.isForeign) }
            else { return error(em.procUndeclaredDirective) }
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { return error(em.procForeignUnexpectedBody) }
            if let error = doStatements(in: globalScope.copy()).then({ scope = Code(code: $0) }) { return .failure(error) }
        }
        else {
            return error(em.procExpectedBody)
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        if let e = verifyNameConflict(procedure) { return error(e) }
        appendDeclaration(procedure, to: globalScope)
        return .success(procedure)
    }
    
    // MARK: - IF-ELSE -
    
    func doIf(in scope: Scope) -> Result<Condition, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        assert(consumeKeyword(.if))
        let hasParenthesis = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        if hasParenthesis {
            if let error = doExpression(in: scope).then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParenthesis) }
        }
        if !consumePunct("{") { return error(em.ifExpectedBrackets) }
        if let error = doStatements(in: scope.copy()).then({ ifBody = $0 }) { return .failure(error) }
        guard consumePunct("}") else { return error(em.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(em.ifExpectedBrackets) }
            if let error = doStatements(in: scope.copy()).then({ elseBody = $0 }) { return .failure(error) }
            guard consumePunct("}") else { return error(em.ifExpectedBrackets) }
        }
        let ifStatement = Condition(condition: condition, block: Code(code: ifBody), elseBlock: Code(code: elseBody))
        return .success(ifStatement)
    }
    
    // MARK: - WHILE LOOP -
    
    func matchWhile() -> Bool {
        (token.value as? Keyword) == .while
            || (token.value is Identifier // "label: while"
                && (peekNext()?.value as? Punctuator)?.value == ":"
                && (peekNext(index: 2)?.value as? Keyword) == .while)
    }
    
    func doWhile(in scope: Scope) -> Result<WhileLoop, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        var label: String?
        if let identifier = token.value as? Identifier, consumePunct(":") {
            label = identifier.value
        }
        assert(consumeKeyword(.while))
        let hasParenthesis = consumePunct("(")
        var condition: Expression!
        var loopBody: [Statement] = []
        if hasParenthesis {
            if let error = doExpression(in: scope).then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParenthesis) }
        }
        if !consumePunct("{") { return error(em.loopExpectedBrackets) }
        if let error = doStatements(in: scope.copy()).then({ loopBody = $0 }) { return .failure(error) }
        guard consumePunct("}") else { return error(em.loopExpectedBrackets) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(code: loopBody))
        return .success(whileStatement)
    }
 
    // MARK: - EXPRESSIONS -
    
    func doExpression(in scope: Scope) -> Result<Expression, ParserError> {
        startCursor = token.startCursor
        defer { endCursor = token.endCursor }
        let expression: Expression
        switch token.value {
        case let literal as TokenLiteral:
            switch literal.value {
            case .int(let value): expression = IntLiteral(value: value)
            case .bool(let value): expression = BoolLiteral(value: value)
            case .float(let value): expression = FloatLiteral(value: value)
            case .string(let value): expression = StringLiteral(value: value)
            }
            nextToken()
        case let identifier as Identifier:
            if matchProcedureCall() {
                var ex: Expression!
                if let error = doProcedureCall(in: scope).then({ ex = $0 }) { return .failure(error) }
                expression = ex
            }
            else {
                expression = Value(name: identifier.value, exprType: .unresolved(name: nil))
                
                if let statement = scope.declarations[identifier.value] {
                    if let variable = statement as? VariableDeclaration {
                        expression.exprType = variable.exprType
                        switch variable.exprType {
                        case .resolved: break
                        default: appendUnresolved(identifier.value, expression)
                        }
                    }
                    else { return error(em.assignPassedNotValue(statement)) }
                }
                nextToken()
            }
        default:
            print("Expression unknown \(token)")
            return error(em.notImplemented)
        }
        
        return .success(expression)
    }
    
    // MARK: - STATEMENTS -
    
    func doStatements(in scope: Scope) -> Result<[Statement], ParserError> {
        // body of: procedure, if-else, loop
        var statements: [Statement] = []
        loop: while tokens.count > i {
            switch token.value  {
            case let punct as Punctuator:
                if punct.value == "}" { // done with the scope
                    return .success(statements)
                }
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                if keyword == .func {
                    return error(em.procNestedNotSupported)
                }
                else if keyword == .if {
                    if let error = doIf(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                else if matchWhile() {
                    if let error = doWhile(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                else if consumeKeyword(.return) {
                    var returnExpression: Expression?
                    if let error = doExpression(in: scope).then({ returnExpression = $0 }) { return .failure(error) }
                    guard consumeSep(";") else { return error(em.expectedSemicolon) }
                    let returnStatement = Return(value: returnExpression ?? VoidLiteral())
                    statements.append(returnStatement)
                }
                else {
                    print("Unexpected keyword: \(keyword.rawValue)")
                    return error(em.notImplemented)
                }
            case is Identifier: // @Clean: this is a copy from the main loop
                if matchVarDecl() {
                    if let error = doVarDecl(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                else {
                    print("(statements loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                    return error(em.notImplemented)
                }
            case is Comment:
                if !nextToken() { break loop }
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop }}
                
            default:
                print("(statements loop) Unexpected token\n\(token)\n")
                return error(em.notImplemented)
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
        self.em.p = self
    }
    
    let fileName: String?
    let tokens: [Token]
    
    // Variables
    
    let em: ErrorMessage = ErrorMessage()
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var globalScope = Scope() /// all declarations in global scope
    var i = 0
    var token: Token
    var statements: [Statement] = []
    
    func parse() -> Result<Code, ParserError> {
        
        // Cycle
        
        loop: while tokens.count > i {
            switch token.value  {
            case let keyword as Keyword:
                if keyword == .func {
                    if let error = doProcDecl(in: globalScope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if keyword == .struct {
                    if let error = doStructDecl().then({ statements.append($0) }) { return .failure(error)}
                    break
                }
                if keyword == .if {
                    return error(em.ifNotExpectedAtGlobalScope)
                }
                if matchWhile() {
                    return error(em.loopNotExpectedAtGlobalScope)
                    
                }
                
                print("Keyword \(keyword.rawValue) is not YET implemented.")
                return error(em.notImplemented)
                    
            case is Identifier:
                if matchWhile() {
                    return error(em.loopNotExpectedAtGlobalScope)
                }
                if matchVarDecl() {
                    if let error = doVarDecl(in: globalScope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                
                print("(main loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                return error(em.notImplemented)
            
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop } /* ignore */ }
                
            default: if !nextToken() { break loop }
            }
        }
        return .success(Code(code: statements))
    }
}
