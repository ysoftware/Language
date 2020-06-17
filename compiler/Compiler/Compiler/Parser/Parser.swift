//
//  Parser.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

// @Todo: proc call doesn't fail without semicolon at the end
// @Todo: propagate erros with exceptions?

extension Parser {
    
    // MARK: - VARIABLE ASSIGNMENT -
    
    func matchVarAssignment() -> Bool {
        token.value is Identifier && (peekNext()?.value as? Operator)?.value == "="
    }
    
    func doVarAssign(in scope: Scope) -> Result<VariableAssignment, ParserError> {
        let start = token.startCursor
        guard let (idToken, idVal) = consumeIdent() else { assert(false) }
        let identifier = idVal.value
        assert(consumeOp("="))
        
        // find variable in scope
        guard let ast = scope.declarations[identifier]
            else { return error(em.assignUndeclared(identifier), idToken.startCursor, idToken.endCursor) }
        guard let varDecl = ast as? VariableDeclaration
            else { return error(em.assignPassedNotValue(ast), idToken.startCursor, idToken.endCursor) }
        guard !varDecl.flags.contains(.isConstant)
            else { return error(em.assignConst(identifier), idToken.startCursor, idToken.endCursor) }
        
        var expr: Expression!
        if let error = doExpression(in: scope).assign(&expr) { return .failure(error) }
        
        // @Todo: refactor to "getType(...) -> Type"
        guard expr.exprType.equals(to: varDecl.exprType) else {
            return error(em.assignTypeMismatch(varDecl.exprType, expr.exprType))
        }
        let assign = VariableAssignment(
            receiverId: identifier, expression: expr, startCursor: start, endCursor: expr.endCursor)
        return .success(assign)
    }
    
    // MARK: - VARIABLE DECLARATION -
    
    func matchVarDecl() -> Bool {
        token.value is Identifier
            && (peekNext()?.value as? Punctuator)?.value == ":"
            && (peekNext()?.value is Identifier
                || (peekNext()?.value as? Punctuator)?.value == "="
                || (peekNext()?.value as? Punctuator)?.value == ":")
    }
    
    func doVarDecl(in scope: Scope) -> Result<VariableDeclaration, ParserError> {
        let start = token.startCursor
        guard let identifier = consumeIdent() else { assert(false) }
        assert(consumePunct(":"))
        
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let declType = consumeIdent()
        var expectingExpression = true
        let end = token.endCursor
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            if let error = doExpression(in: scope).assign(&expr) { return .failure(error) }
            if let declaredTypeName = declType?.value.value, let exprType = expr?.exprType {
                let declaredType = Type.named(declaredTypeName)
                
                if let converted = convertExpression(expr!, to: declaredType) {
                    expr = converted
                }
//                if let literal = expr as? LiteralExpr, literal.isConvertible(to: declaredType) {
//                    literal.exprType = declaredType
//                }
                else if !declaredType.equals(to: exprType) {
                    return error(em.varDeclTypeMismatch(exprType, declaredType),
                                 declType?.token.startCursor, declType?.token.endCursor)
                }
            }
        }
        else if !consumeSep(";") { return error(em.expectedSemicolon) }

        // variable type inference
        let type: Type
        if let t = expr?.exprType { type = t }
            
        else if let name = declType?.value.value {
            type = resolveType(name)
        }
        else { return error(em.varDeclRequiresType) } // @Todo: check cursors and if this error is even valid
        
        let varDecl = VariableDeclaration(
            name: identifier.value.value, exprType: type, flags: flags, expression: expr,
            startCursor: start, endCursor: end)
        
        if let custom = type as? StructureType { appendUnresolved(custom.name, varDecl) }
        
        if let e = verifyNameConflict(varDecl, in: scope) { return error(e) }
        appendDeclaration(varDecl, to: scope)
        return .success(varDecl)
    }
    
    // MARK: - STRUCT DECLARATION -

    func doStructDecl() -> Result<StructDeclaration, ParserError> {
        let start = token.startCursor
        assert(consumeKeyword(.struct))
        guard let name = consumeIdent()?.value
            else { return error(em.structExpectedName) }
        let end = token.endCursor
        guard consumePunct("{")
            else { return error(em.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        let structScope = globalScope.next()
        while tokens.count > i {
            var member: VariableDeclaration?
            if matchVarDecl() {
                if let error = doVarDecl(in: structScope).assign(&member) { return .failure(error) }
                members.append(member!)
            }
            else {
                if consumePunct("}") { break }
                else { return error(em.structExpectedBracketsEnd) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, members: members,
                                           startCursor: start, endCursor: end)
        if let e = verifyNameConflict(structDecl) { return error(e) }
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
            else { report("call matchProcedureCall required before calling this") }
        var arguments: [Expression] = []
        while tokens.count > i { // PROCEDURE CALL ARGUMENTS
            if (token.value as? Punctuator)?.value == ")" { break }
            if let error = doExpression(in: scope, expectSemicolon: false).then({ arguments.append($0) }) { return .failure(error) }
            if !consumeSep(",") { break }
        }
        guard consumePunct(")") else { return error(em.callExpectedClosingParentheses,
                                                    lastToken.endCursor.advancingCharacter()) }
        let end = lastToken.endCursor
        var returnType: Type = .unresolved
        
        let foundDecl = scope.declarations[name.value] // ?? internalProcedures[name.value]
        
        if let statement = foundDecl { // else - proceed
            if let procDecl = statement as? ProcedureDeclaration {
                returnType = procDecl.returnType
                
                let minArgWithoutVararg = procDecl.arguments.count - (procDecl.flags.contains(.isVarargs) ? 1 : 0)
                guard arguments.count >= minArgWithoutVararg else {
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
                    
                    if !declArgument.exprType.isResolved {
                        arguments[i].exprType = resolveType(declArgument.exprType.typeName)
                    }
                    else if !declArgument.exprType.equals(to: arguments[i].exprType) {
                        return error(em.callArgumentTypeMismatch(
                            declArgument.exprType.typeName, arguments[i].exprType.typeName),
                                     arguments[i].startCursor, arguments[i].endCursor)
                    }
                }
            }
            else { return error(em.callNotProcedure, identToken.startCursor, identToken.endCursor) }
        }

        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments)
        call.startCursor = start
        call.endCursor = end
        if !returnType.isResolved {
            appendUnresolved(returnType.typeName, call)
        }
        return .success(call)
    }
    
    // MARK: - PROCEDURE DECLARATION -

    func doProcDecl(in scope: Scope) -> Result<ProcedureDeclaration, ParserError> {
        let start = token.startCursor
        assert(consumeKeyword(.func))
        guard let procName = consumeIdent()?.value else { return error(em.procExpectedName) }
        guard consumePunct("(") else { return error(em.expectedParentheses) }
        let end = lastToken.endCursor
        let returnType: Type
        let name = procName.value
        var id = "\(procName.value)"
        var arguments: [Value] = []
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
                guard let argName = consumeIdent()?.value.value, consumePunct(":"),
                    let argType = consumeIdent()?.value
                    else { return error(em.procExpectedArgumentType) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                arguments.append(Value(name: argName, exprType: .named(argType.value)))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { return error(em.procArgumentParentheses) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = .named(type.value) }
            else { return error(em.procReturnTypeExpected) }
        }
        else { returnType = .void }
        if let (directiveToken, directive) = consume(Directive.self) {
            switch directive.value {
            case "foreign":
                flags.insert(.isForeign)
                id = procName.value
            case "main":
                flags.insert(.main)
                isForceEntry = true
            default:
                return error(em.procUndeclaredDirective, directiveToken.startCursor, directiveToken.endCursor)
            }
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { return error(em.procForeignUnexpectedBody) }
            
            let procedureScope = globalScope.next()
            arguments.forEach { arg in
                let decl = VariableDeclaration(name: arg.name, exprType: arg.exprType,
                                               flags: [.isConstant], expression: arg)
                procedureScope.declarations[arg.name] = decl
            }
            
            if let error = doStatements(in: procedureScope).then({ scope = Code($0) }) { return .failure(error) }

            while let returnStat = firstNotMatchingReturnStatement(in: scope, to: returnType) {
                if let fixedExpr = convertExpression(returnStat.value, to: returnType) {
                    returnStat.value = fixedExpr
                    continue
                }
                return error(em.returnTypeNotMatching(returnType, returnStat.value.exprType),
                             returnStat.value.startCursor, returnStat.value.endCursor)
            }
            
            if !(scope.statements.last is Return) {
                if returnType.equals(to: .void) { scope.statements.append(Return(value: VoidLiteral())) }
                else { return error(em.procNotReturning) }
            }
        }
        else {
            return error(em.procExpectedBody)
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
        let tok = token
        assert(consumeKeyword(.if))
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        if hasParentheses {
            if let error = doExpression(in: scope, expectSemicolon: false).assign(&condition) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { return error(em.ifExpectedBrackets) }
        if let error = doStatements(in: scope.next()).assign(&ifBody) { return .failure(error) }
        guard consumePunct("}") else { return error(em.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(em.ifExpectedBrackets) }
            if let error = doStatements(in: scope.next()).assign(&elseBody) { return .failure(error) }
            guard consumePunct("}") else { return error(em.ifExpectedBrackets) }
        }
        let ifStatement = Condition(condition: condition, block: Code(ifBody), elseBlock: Code(elseBody),
                                    startCursor: tok.startCursor, endCursor: tok.endCursor)
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
        let start = token.startCursor
        let labelIdent = consumeIdent()
        let label = labelIdent?.value.value
        if labelIdent != nil { assert(consumePunct(":")) }
        let end = token.endCursor
        assert(consumeKeyword(.while))
        if let labelIdent = labelIdent {
            if scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelDuplicate, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        var loopBody: [Statement] = []
        if hasParentheses {
            if let error = doExpression(in: scope, expectSemicolon: false).assign(&condition) { return .failure(error) }
            if !consumePunct(")") { return error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { return error(em.loopExpectedBrackets) }
        if let error = doStatements(in: scope.next(as: ContextLoop(label: label))).assign(&loopBody) { return .failure(error) }
        guard consumePunct("}") else { return error(em.loopExpectedBrackets) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(loopBody),
                                       startCursor: start, endCursor: end)
        return .success(whileStatement)
    }
    
    func doBreak(in scope: Scope) -> Result<Break, ParserError> {
        let tok = token
        assert(consumeKeyword(.break))
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { return error(em.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { return error(em.breakContext, tok.startCursor, tok.endCursor) }
        }
        let br = Break(userLabel: labelIdent?.value.value, startCursor: tok.startCursor, endCursor: tok.endCursor)
        return .success(br)
    }
    
    func doContinue(in scope: Scope) -> Result<Continue, ParserError> {
        let tok = token
        assert(consumeKeyword(.continue))
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { return error(em.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { return error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { return error(em.continueContext, tok.startCursor, tok.endCursor) }
        }
        let cont = Continue(userLabel: labelIdent?.value.value, startCursor: tok.startCursor, endCursor: token.endCursor)
        return .success(cont)
    }
    
    // MARK: - EXPRESSIONS -
    
    func doExpression(in scope: Scope,
                      expectSemicolon: Bool = true,
                      _ priority: Int = 0) -> Result<Expression, ParserError> {
        guard tokens.count > i else { return error(em.unexpectedEndOfFile, lastToken.endCursor) }

        var left: Expression!
        if let error = doExpr(in: scope).assign(&left) { return .failure(error) }
        
        while let op = token.value as? Operator, let opPriority = precedence(of: op.value), opPriority >= priority {
            _ = consumeOperator()
            var right: Expression!
            if let error = doExpression(in: scope, expectSemicolon: false, opPriority + 1)
                .assign(&right) { return .failure(error) }
    
            if !left.exprType.equals(to: right.exprType) {
                if let r = convertExpression(right, to: left.exprType) {
                    right = r
                }
                else if let l = convertExpression(left, to: right.exprType) {
                    left = l
                }
            }
            
            guard left.exprType.equals(to: right.exprType) else {
                return error(em.binopArgTypeMatch(left.exprType, r: right.exprType), left.startCursor, right.endCursor)
            }
            guard isAccepting(op.value, argType: left.exprType) else {
                return error(em.binopArgTypeSupport(op.value, t: left.exprType), left.startCursor, right.endCursor)
            }
            
            let type = returnType(ofBinaryOperation: op.value, arg: left.exprType)
            left = BinaryOperator(name: op.value, exprType: type, arguments: (left, right),
                                  startCursor: left.startCursor, endCursor: right.endCursor)
        }
        
        if expectSemicolon, !consumeSep(";") { return error(em.expectedSemicolon) }
        return .success(left)
    }
    
    /// A single unit expression: `literal`, `value`, `procedure call`.
    func doExpr(in scope: Scope) -> Result<Expression, ParserError> {
        let start = token.startCursor
        
        // @Todo: member access
        // @Todo: subscript

        var arg: Expression!
        if consumePunct("(") {
            if let error = doExpression(in: scope, expectSemicolon: false)
                .assign(&arg) { return .failure(error) }
            if !consumePunct(")") { return error(em.ifExpectedBrackets) }
            return .success(arg)
        }
        else if let (opTok, op) = consumeOperator() { // unary operation
            if let error = doExpr(in: scope).assign(&arg) { return .failure(error) }
            
            let type = returnType(ofUnaryOperation: op.value, arg: arg.exprType)
            let op = UnaryOperator(name: op.value, exprType: type, argument: arg)
            op.startCursor = opTok.startCursor
            op.endCursor = opTok.endCursor
            return .success(op)
        }
        
        let expression: Expression
        switch token.value {
        case let literal as TokenLiteral:
            switch literal.value {
            case .int(let value): expression = IntLiteral(value: value)
            case .bool(let value): expression = IntLiteral(value: value ? 1 : 0, exprType: .bool)
            case .float(let value): expression = FloatLiteral(value: value)
            case .string(let value): expression = StringLiteral(value: value)
            }
            if !nextToken() { return error(em.unexpectedEndOfFile) }
        case let identifier as Identifier:
            let tok = token
            if matchProcedureCall() {
                var ex: ProcedureCall!
                if let error = doProcedureCall(in: scope).assign(&ex) { return .failure(error) }
                expression = ex
            }
            else {
                expression = Value(name: identifier.value, exprType: .unresolved)
                if let statement = scope.declarations[identifier.value] {
                    if let variable = statement as? VariableDeclaration {
                        expression.exprType = variable.exprType
                        
                        if !variable.exprType.isResolved {
                            appendUnresolved(identifier.value, expression)
                        }
                    }
                    else { return error(em.assignPassedNotValue(statement), tok.startCursor, tok.endCursor) }
                }
                if !nextToken() { return error(em.unexpectedEndOfFile) }
            }
        case is Punctuator: return error(em.expectedExpression)
        case is Separator: return error(em.expectedExpression)
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
                    if !consumeSep(";") {
                        if let error = doExpression(in: scope, expectSemicolon: false).assign(&returnExpression)
                            { return .failure(error) }
                    }
                    let end = returnExpression?.endCursor ?? lastToken.endCursor
                    let returnStatement = Return(
                        value: returnExpression ?? VoidLiteral(),
                        startCursor: lastToken.startCursor, endCursor: end)
                    statements.append(returnStatement)
                    break
                }
                print("Unexpected keyword: \(keyword.rawValue)")
                return error(em.notImplemented, token.startCursor, token.endCursor)
                
            case is Identifier: // @Clean: this is a copy from the main loop
                if matchVarAssignment() {
                    if let error = doVarAssign(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
                if matchProcedureCall() {
                    if let error = doProcedureCall(in: scope).then({ statements.append($0) }) { return .failure(error) }
                    break
                }
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
                
            case is EOF:
                break loop
            default:
                print("(statements loop) Unexpected token\n\(token)\n")
                return error(em.notImplemented, token.startCursor, token.endCursor)
            }
        }
        return .success(statements)
    }
}

// MARK: - Parser

final class Parser {
    
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
                if matchWhile() { return error(em.loopNotExpectedAtGlobalScope) }
                
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
