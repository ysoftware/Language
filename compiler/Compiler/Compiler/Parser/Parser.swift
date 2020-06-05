//
//  Parser.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
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
        guard let identifier = consumeIdent() else { assert(false) }
        assert(consumePunct(":"))
        
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let suppliedTypeName = consumeIdent()
        var expectingExpression = true
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            if let error = doExpression(in: scope).then({ expr = $0 }) { return .failure(error) }
            if let declaredType = suppliedTypeName, let exprType = expr?.exprType.name {
                if let literal = expr as? LiteralExpr, literal.isCompliable(with: declaredType.value.value) {
                    literal.exprType = .resolved(name: declaredType.value.value)
                }
                else if declaredType.value.value != exprType {
                    return error(em.varDeclTypeMismatch, expr!.startCursor, expr!.endCursor)
                }
            }
        }
        else if !consumeSep(";") { return error(em.expectedSemicolon, lastToken.endCursor.advancingCharacter()) }

        // variable type inference
        let type: Type
        if let t = expr?.exprType { type = t }
        else if let name = suppliedTypeName?.value.value {
            // @Todo: refactor to "getType(...) -> Type" that will resolve type depending on the currently known set of types
            if Type.isPrimitive(name) { type = .type(name: name) }
            else { type = .unresolved(name: name) }
        }
        else { return error(em.varDeclRequiresType, lastToken.endCursor.advancingCharacter()) } // @Todo: check cursors and if this error is even valid
        
        let varDecl = VariableDeclaration(
            name: identifier.value.value, exprType: type, flags: flags, expression: expr)
        if case .resolved = type { appendUnresolved(type.name, varDecl) }
        if let e = verifyNameConflict(varDecl, in: scope) { return error(e, lastToken.endCursor.advancingCharacter()) }
        appendDeclaration(varDecl, to: scope)
        return .success(varDecl)
    }
    
    // MARK: - STRUCT DECLARATION -

    func doStructDecl() -> Result<StructDeclaration, ParserError> {
        assert(consumeKeyword(.struct))
        guard let name = consumeIdent()?.value
            else { return error(em.structExpectedName, lastToken.endCursor.advancingCharacter()) }
        guard consumePunct("{")
            else { return error(em.structExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        var members: [VariableDeclaration] = []
        let structScope = globalScope.next()
        while tokens.count > i {
            var member: VariableDeclaration?
            if matchVarDecl() {
                if let error = doVarDecl(in: structScope).then({ member = $0 }) { return .failure(error) }
                members.append(member!)
            }
            else {
                if consumePunct("}") { break }
                else { return error(em.structExpectedBracketsEnd, lastToken.endCursor.advancingCharacter()) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, members: members)
        if let e = verifyNameConflict(structDecl) { return error(e, lastToken.endCursor.advancingCharacter()) }
        appendDeclaration(structDecl, to: globalScope)
        return .success(structDecl)
    }
    
    // MARK: - PROCEDURE CALL -
    
    func matchProcedureCall() -> Bool {
        token.value is Identifier && (peekNext()?.value as? Punctuator)?.value == "("
    }
    
    func doProcedureCall(in scope: Scope) -> Result<ProcedureCall, ParserError> {
        let start = token.startCursor
        guard let (identToken, name) = consumeIdent(), consumePunct("(")
            else { fatalError("call matchProcedureCall required before calling this") }
        var arguments: [Expression] = []
        while tokens.count > i { // PROCEDURE CALL ARGUMENTS
            if (token.value as? Punctuator)?.value == ")" { break }
            if let error = doExpression(in: scope, expectSemicolon: false).then({ arguments.append($0) }) { return .failure(error) }
            if !consumeSep(",") { break }
        }
        guard consumePunct(")") else { return error(em.callExpectedClosingParentheses,
                                                    lastToken.endCursor.advancingCharacter()) }
        let end = lastToken.endCursor
        var returnType: Type = .unresolved(name: nil)
        if let statement = scope.declarations[name.value] { // else - proceed
            if let procDecl = statement as? ProcedureDeclaration {
                if case .resolved = procDecl.returnType { returnType = procDecl.returnType }
                guard arguments.count >= procDecl.arguments.count else {
                    return error(em.callArgumentsCount(procDecl.arguments.count, arguments.count), start, end)
                }
                for i in 0..<arguments.count {
                    guard procDecl.arguments.count > i || procDecl.flags.contains(.isVarargs) else {
                        if procDecl.flags.contains(.isVarargs) {
                            return error(em.callArgumentsVarCount(procDecl.arguments.count, arguments.count),
                                         start, end)
                        }
                        else {
                            return error(em.callArgumentsCount(procDecl.arguments.count, arguments.count),
                                         start, end)
                        }
                    }
                    let declArgument = procDecl.arguments.count > i ? procDecl.arguments[i] : procDecl.arguments.last!
                    switch arguments[i].exprType {
                        // @Todo: refactor to "getType(...) -> Type"
                    case .resolved(let name), .predicted(let name):
                        if name != declArgument.name {
                            return error(em.callArgumentTypeMismatch(name, e: declArgument.name),
                                         arguments[i].startCursor, arguments[i].endCursor)
                        }
                    case .unresolved(let name):
                        // @Todo: match with structs if not primitive (the block inside if)
                        if let name = name { arguments[i].exprType = .type(name: name) }
                        else { arguments[i].exprType = .predicted(name: declArgument.name) }
                    }
                }
            }
            else { return error(em.callNotProcedure, identToken.startCursor, identToken.endCursor) }
        }

        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments)
        call.startCursor = start
        call.endCursor = end
        if case .resolved = returnType { appendUnresolved(returnType.name, call) }
        return .success(call)
    }
    
    // MARK: - PROCEDURE DECLARATION -

    func doProcDecl(in scope: Scope) -> Result<ProcedureDeclaration, ParserError> {
        let start = token.startCursor
        var end = token.endCursor
        assert(consumeKeyword(.func))
        guard let procName = consumeIdent()?.value else { return error(em.procExpectedName, lastToken.endCursor.advancingCharacter()) }
        guard consumePunct("(") else { return error(em.expectedParentheses, lastToken.endCursor.advancingCharacter()) }
        let returnType: Type
        let name = procName.value
        var id = "__global_func_\(procName.value)" // @Todo: don't change the name of 'main'? or create a #main directive
        var arguments: [Type] = []
        var flags = ProcedureDeclaration.Flags()
        var scope: Code = .empty
        var isForceEntry = false
        while tokens.count > i { // PROCEDURE ARGUMENTS DECLARATION
            if (token.value as? Punctuator)?.value == ")" { break }
            if consumePunct("...") {
                if arguments.isEmpty { return error(em.procExpectedArgumentBeforeVarargs, tokens[i-2].endCursor.advancingCharacter()) }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard token.value is Identifier else {
                    return error(em.procExpectedArgumentName, token.startCursor, token.endCursor)
                }
                guard let _ = consumeIdent()?.value, consumePunct(":"),
                    let argType = consumeIdent()?.value
                    else { return error(em.procExpectedArgumentType, lastToken.endCursor.advancingCharacter()) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(.type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { return error(em.procArgumentParentheses, lastToken.endCursor.advancingCharacter()) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = .type(name: type.value) }
            else { return error(em.procReturnTypeExpected, lastToken.endCursor.advancingCharacter()) }
        }
        else { returnType = .void }
        // @Todo: check all return statements to match return value
        // @Todo: static analysis of
        end = lastToken.endCursor
        if let (directiveToken, directive) = consume(Directive.self) {
            switch directive.value {
            case "foreign": flags.insert(.isForeign)
            case "main":
                flags.insert(.main)
                isForceEntry = true
            default:
                return error(em.procUndeclaredDirective, directiveToken.startCursor, directiveToken.endCursor)
            }
            end = directiveToken.endCursor
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { return error(em.procForeignUnexpectedBody, lastToken.endCursor.advancingCharacter()) }
            if let error = doStatements(in: globalScope.next()).then({ scope = Code($0) }) { return .failure(error) }
        }
        else {
            return error(em.procExpectedBody, lastToken.endCursor.advancingCharacter())
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        let previousForceEntry = entry?.flags.contains(.main) ?? false
        if previousForceEntry && isForceEntry { return error(em.procMainRedecl, start, end) }
        if name == "main" && entry == nil || isForceEntry {
            entry = procedure
            id = procName.value
        }
        if let e = verifyNameConflict(procedure) { return error(e, start, end) }
        appendDeclaration(procedure, to: globalScope)
        procedure.startCursor = start
        procedure.endCursor = end
        return .success(procedure)
    }
    
    // MARK: - IF-ELSE -
    
    func doIf(in scope: Scope) -> Result<Condition, ParserError> {
        assert(consumeKeyword(.if))
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        if hasParentheses {
            if let error = doExpression(in: scope, expectSemicolon: false).then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParentheses, lastToken.endCursor.advancingCharacter()) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { return error(em.ifExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        if let error = doStatements(in: scope.next()).then({ ifBody = $0 }) { return .failure(error) }
        guard consumePunct("}") else { return error(em.ifExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(em.ifExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
            if let error = doStatements(in: scope.next()).then({ elseBody = $0 }) { return .failure(error) }
            guard consumePunct("}") else { return error(em.ifExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        }
        let ifStatement = Condition(condition: condition, block: Code(ifBody), elseBlock: Code(elseBody))
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
        let labelIdent = consumeIdent()
        let label = labelIdent?.value.value
        if labelIdent != nil { assert(consumePunct(":")) }
        assert(consumeKeyword(.while))
        if let labelIdent = labelIdent {
            if scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelDuplicate, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        var loopBody: [Statement] = []
        if hasParentheses {
            if let error = doExpression(in: scope, expectSemicolon: false).then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParentheses, lastToken.endCursor.advancingCharacter()) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { return error(em.loopExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        if let error = doStatements(in: scope.next(as: ContextLoop(label: label))).then({ loopBody = $0 }) { return .failure(error) }
        guard consumePunct("}") else { return error(em.loopExpectedBrackets, lastToken.endCursor.advancingCharacter()) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(loopBody))
        return .success(whileStatement)
    }
    
    func doBreak(in scope: Scope) -> Result<Break, ParserError> {
        let tok = token
        assert(consumeKeyword(.break))
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { return error(em.expectedSemicolon, lastToken.endCursor.advancingCharacter()) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { return error(em.breakContext, tok.startCursor, tok.endCursor) }
        }
        return .success(Break(userLabel: labelIdent?.value.value))
    }
    
    func doContinue(in scope: Scope) -> Result<Continue, ParserError> {
        let tok = token
        assert(consumeKeyword(.continue))
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { return error(em.expectedSemicolon, lastToken.endCursor.advancingCharacter()) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { return error(em.continueContext, tok.startCursor, tok.endCursor) }
        }
        return .success(Continue(userLabel: labelIdent?.value.value))
    }
    
    // MARK: - EXPRESSIONS -
    
    func doExpression(in scope: Scope, expectSemicolon: Bool = true) -> Result<Expression, ParserError> {
        // @Todo: binary operators
        while tokens.count > i {
            var left: Expression!
            if let error = doExpr(in: scope).then({ left = $0 }) { return .failure(error) }
                        
//            if let op = consumeOperator()?.value {
//                var right: Expression!
//                if let error = doExpr(in: scope).then({ right = $0 }) { return .failure(error) }
//            }

            if expectSemicolon {
                if consumeSep(";") { return .success(left) }
                else { return error(em.expectedSemicolon, lastToken.endCursor.advancingCharacter()) }
            }
            return .success(left)
        }
        return doExpr(in: scope)
    }
    
    func doExpr(in scope: Scope) -> Result<Expression, ParserError> {
        let start = token.startCursor
        
        // @Todo: member access
        // @Todo: subscript
        // @Todo: brackets "(1 + 2) * 3"
        
        // @Todo: unary operators
        
        let expression: Expression
        switch token.value {
        case let literal as TokenLiteral:
            switch literal.value {
            case .int(let value): expression = IntLiteral(value: value)
            case .bool(let value): expression = BoolLiteral(value: value)
            case .float(let value): expression = FloatLiteral(value: value)
            case .string(let value): expression = StringLiteral(value: value)
            }
            if !nextToken() { return error(em.unexpectedEndOfFile, lastToken.endCursor.advancingCharacter()) }
        case let identifier as Identifier:
            let tok = token
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
                    else { return error(em.assignPassedNotValue(statement), tok.startCursor, tok.endCursor) }
                }
                if !nextToken() { return error(em.unexpectedEndOfFile, lastToken.endCursor.advancingCharacter()) }
            }
        case is Punctuator:
            return error(em.expectedExpression, lastToken.endCursor.advancingCharacter())
        case is Separator:
            return error(em.expectedExpression, lastToken.endCursor.advancingCharacter())
        default:
            print("Expression unknown: \(token)")
            return error(em.notImplemented, token.startCursor, token.endCursor)
        }
        expression.startCursor = start
        expression.endCursor = lastToken.endCursor
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
                    return error(em.procNestedNotSupported, token.startCursor, token.endCursor)
                }
                if keyword == .break {
                    if let error = doBreak(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if keyword == .continue {
                    if let error = doContinue(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if keyword == .if {
                    if let error = doIf(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if matchWhile() {
                    if let error = doWhile(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if consumeKeyword(.return) {
                    var returnExpression: Expression?
                    if let error = doExpression(in: scope).then({ returnExpression = $0 }) { return .failure(error) }
                    let returnStatement = Return(value: returnExpression ?? VoidLiteral())
                    statements.append(returnStatement)
                    break
                }
                print("Unexpected keyword: \(keyword.rawValue)")
                return error(em.notImplemented, token.startCursor, token.endCursor)
                
            case is Identifier: // @Clean: this is a copy from the main loop
                if matchWhile() {
                    if let error = doWhile(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if matchVarDecl() {
                    if let error = doVarDecl(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                print("(statements loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                return error(em.notImplemented, token.startCursor, token.endCursor)
            case is Comment:
                if !nextToken() { break loop }
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop }}
                
            default:
                print("(statements loop) Unexpected token\n\(token)\n")
                return error(em.notImplemented, token.startCursor, token.endCursor)
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
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var globalScope = Scope() /// all declarations in global scope
    var i = 0
    var token: Token
    var statements: [Statement] = []
    var entry: ProcedureDeclaration?
    
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
                if keyword == .if { return error(em.ifNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if matchWhile() { return error(em.loopNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if keyword == .break { return error(em.breakContext, token.startCursor, token.endCursor) }
                if keyword == .continue { return error(em.continueContext, token.startCursor, token.endCursor) }
                if keyword == .fallthrough { return error("@Todo: FALLTHROUGH ERROR MESSAGE", token.startCursor, token.endCursor) }

                print("Keyword \(keyword.rawValue) is not YET implemented.")
                return error(em.notImplemented, token.startCursor, token.endCursor)
                    
            case is Identifier:
                if matchWhile() {
                    return error(em.loopNotExpectedAtGlobalScope, lastToken.endCursor.advancingCharacter())
                }
                if matchVarDecl() {
                    if let error = doVarDecl(in: globalScope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                
                print("(main loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                return error(em.notImplemented, token.startCursor, token.endCursor)
            
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop } /* ignore */ }
                
            default: if !nextToken() { break loop }
            }
        }
        return .success(Code(statements))
    }
}
