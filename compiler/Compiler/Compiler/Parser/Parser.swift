//
//  Parser.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

extension Parser {
    
    // MARK: - MEMBER ACCESS -
    
    func matchMemberAccess() -> Bool {
        (token.value as? Punctuator)?.value == "." && peekNext()?.value is Identifier
    }
    
    func doMemberAccess(of base: Expression, in scope: Scope) throws -> Expression {
        guard consumePunct(".") else { report("call matchMemberAccess required before calling this") }
        
        if let value = base as? Value, value.exprType.equals(to: .unresolved) {
            if let decl = scope.declarations[value.name] as? VariableDeclaration {
                base.exprType = decl.exprType
            }
        }
        guard let memberIdent = consumeIdent() else {
            throw error(em.expectedMemberIdentifier, token.startCursor, token.endCursor)
        }
        let member = memberIdent.value.value
        let info = try resolveMemberTypeAndIndex(name: member, of: base)
        let memberType = info?.type ?? .unresolved
        let memberIndex = info?.index
        let access = MemberAccess(base: base, memberName: member, memderIndex: memberIndex, exprType: memberType,
                                  startCursor: base.startCursor, endCursor: memberIdent.token.endCursor)
        return access
    }
    
    // MARK: - ASSIGNMENT -
    
    /// Returns a thing we're going to assign to
    func matchAssignment(in scope: Scope) throws -> Ast? {
        
        if let identifier = token.value as? Identifier {
            
            // find variable in scope
            guard let ast = scope.declarations[identifier.value]
                else { throw error(em.assignUndeclared(identifier.value), token.startCursor, token.endCursor) }
            guard let varDecl = ast as? VariableDeclaration
                else { throw error(em.assignPassedNotValue(ast), token.startCursor, token.endCursor) }
            guard !varDecl.flags.contains(.isConstant)
                else { throw error(em.assignConst(identifier.value), token.startCursor, token.endCursor) }
            
            var base: Expression = Value(name: identifier.value, exprType: varDecl.exprType,
                                         startCursor: token.startCursor, endCursor: token.endCursor)
            if !nextToken() { throw error(em.unexpectedEndOfFile) }
            while matchMemberAccess() {
                base = try doMemberAccess(of: base, in: scope)
            }
            // @Todo: check root member access base existence
            
            guard consumeOp("=") else { throw error(em.unexpectedMemberAccess, base.startCursor, base.endCursor) }
            return base
        }
        
        return nil
    }
    
    func doAssign(to rValue: Ast, in scope: Scope) throws -> Assignment {
        let start = rValue.startCursor
        
        var expectingType: Type!
        if let expr = rValue as? Expression {
            expectingType = expr.exprType
        }
        
        let expr = try doExpression(in: scope)
        if !expectingType.equals(to: .unresolved) {
            // @Todo: resolve expression type
            guard expr.exprType.equals(to: expectingType) else {
                throw error(em.assignTypeMismatch(expectingType, expr.exprType), expr.startCursor, expr.endCursor)
            }
        }
        
        let assign = Assignment(
            receiver: rValue, expression: expr, startCursor: start, endCursor: expr.endCursor)
        return assign
    }
    
    // MARK: - VARIABLE DECLARATION -
    
    func matchVarDecl() -> Bool {
        token.value is Identifier
            && (peekNext()?.value as? Punctuator)?.value == ":"
            && (peekNext()?.value is Identifier
                || (peekNext()?.value as? Punctuator)?.value == "="
                || (peekNext()?.value as? Punctuator)?.value == ":")
    }
    
    func doVarDecl(in scope: Scope) throws -> VariableDeclaration {
        let start = token.startCursor
        guard let identifier = consumeIdent(), consumePunct(":")
            else { report("call matchVarDecl required before calling this") }
        
        var expr: Expression?
        var flags: VariableDeclaration.Flags = []
        let declType = consumeIdent()
        var expectingExpression = true
        let end = token.endCursor
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            expr = try doExpression(in: scope)
            if let declaredTypeName = declType?.value.value, let exprType = expr?.exprType {
                let declaredType = Type.named(declaredTypeName)
                
                if let converted = convertExpression(expr!, to: declaredType) {
                    expr = converted
                }
                else if !declaredType.equals(to: exprType) {
                    throw error(em.varDeclTypeMismatch(exprType, declaredType),
                                 declType?.token.startCursor, declType?.token.endCursor)
                }
            }
        }
        else if !consumeSep(";") { throw error(em.expectedSemicolon) }

        // variable type inference
        let type: Type
        if let t = expr?.exprType {
            type = t
        }
        else if let declType = declType {
            guard let resolvedType = resolveType(named: declType.value.value) else {
                throw error(em.declTypeIsDeclaration(), declType.token.startCursor, declType.token.endCursor)
            }
            type = resolvedType
        }
        else { throw error(em.varDeclRequiresType) } // @Todo: check cursors and if this error is even valid
        
        let varDecl = VariableDeclaration(
            name: identifier.value.value, exprType: type, flags: flags, expression: expr,
            startCursor: start, endCursor: end)
        
        // @Todo: check that dependency is added correctly for unresolved
        // we're supposed to add this decl as a dependant on the expression
        
        if let e = verifyNameConflict(varDecl, in: scope) { throw error(e) }
        appendDeclaration(varDecl, to: scope)
        return varDecl
    }
    
    // MARK: - STRUCT DECLARATION -

    func doStructDecl() throws -> StructDeclaration {
        let start = token.startCursor
        guard consumeKeyword(.struct) else { report("can't call doStructDecl without checking for keyword first") }
        guard let name = consumeIdent()?.value
            else { throw error(em.structExpectedName) }
        let end = token.endCursor
        guard consumePunct("{")
            else { throw error(em.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        let structScope = globalScope.next()
        while tokens.count > i {
            var member: VariableDeclaration?
            if matchVarDecl() {
                member = try doVarDecl(in: structScope)
                members.append(member!)
            }
            else {
                if consumePunct("}") { break }
                else { throw error(em.structExpectedBracketsEnd) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, members: members,
                                           startCursor: start, endCursor: end)
        if let e = verifyNameConflict(structDecl) { throw error(e) }
        appendDeclaration(structDecl, to: globalScope)
        return structDecl
    }
    
    // MARK: - PROCEDURE CALL -
    
    func matchProcedureCall() -> Bool {
        token.value is Identifier && (peekNext()?.value as? Punctuator)?.value == "("
    }
    
    func doProcedureCall(in scope: Scope) throws -> ProcedureCall {
        let start = token.startCursor
        guard let (identToken, name) = consumeIdent(), consumePunct("(")
            else { report("call matchProcedureCall required before calling this") }
        var arguments: [Expression] = []
        while tokens.count > i { // PROCEDURE CALL ARGUMENTS
            if (token.value as? Punctuator)?.value == ")" { break }
            let arg = try doExpression(in: scope, expectSemicolon: false)
            arguments.append(arg)
            if !consumeSep(",") { break }
        }
        guard consumePunct(")") else { throw error(em.callExpectedClosingParentheses,
                                                    lastToken.endCursor.advancingCharacter()) }
        let end = lastToken.endCursor
        var returnType: Type = .unresolved
        
        let foundDecl = scope.declarations[name.value] ?? internalProcedures.first(where: { $0.name == name.value })
        
        if let statement = foundDecl { // else - proceed
            if let procDecl = statement as? ProcedureDeclaration {
                returnType = procDecl.returnType
                
                let minArgWithoutVararg = procDecl.arguments.count - (procDecl.flags.contains(.isVarargs) ? 1 : 0)
                guard arguments.count >= minArgWithoutVararg else {
                    throw error(em.callArgumentsCount(procDecl.arguments.count, arguments.count), start, end)
                }
                for i in 0..<arguments.count {
                    guard procDecl.arguments.count > i || procDecl.flags.contains(.isVarargs) else {
                        if procDecl.flags.contains(.isVarargs) {
                            throw error(em.callArgumentsVarCount(procDecl.arguments.count, arguments.count),
                                         start, end)
                        }
                        else {
                            throw error(em.callArgumentsCount(procDecl.arguments.count, arguments.count),
                                         start, end)
                        }
                    }
                    let declArgument = procDecl.arguments.count > i ? procDecl.arguments[i] : procDecl.arguments.last!
                    
                    // @Todo: check that dependency is added correctly for unresolved
                    if !declArgument.exprType.isResolved {
                        arguments[i].exprType = resolveType(of: declArgument)
                    }
                    else if !declArgument.exprType.equals(to: arguments[i].exprType) {
                        throw error(em.callArgumentTypeMismatch(
                            declArgument.exprType.typeName, arguments[i].exprType.typeName),
                                     arguments[i].startCursor, arguments[i].endCursor)
                    }
                }
            }
            else { throw error(em.callNotProcedure, identToken.startCursor, identToken.endCursor) }
        }

        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments)
        call.startCursor = start
        call.endCursor = end
        if !returnType.isResolved {
            appendUnresolved(returnType.typeName, call)
        }
        return call
    }
    
    // MARK: - PROCEDURE DECLARATION -

    func doProcDecl(in scope: Scope) throws -> ProcedureDeclaration {
        let start = token.startCursor
        guard consumeKeyword(.func) else { report("can't call doProcDecl without checking for keyword first") }
        guard let procName = consumeIdent()?.value else { throw error(em.procExpectedName) }
        guard consumePunct("(") else { throw error(em.expectedParentheses) }
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
                if arguments.isEmpty { throw error(em.procExpectedArgumentBeforeVarargs,
                                                   tokens[i-2].endCursor.advancingCharacter()) }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard token.value is Identifier else {
                    throw error(em.procExpectedArgumentName, token.startCursor, token.endCursor)
                }
                guard let argNameTok = consumeIdent(), consumePunct(":"), let argTypeTok = consumeIdent()
                    else { throw error(em.procExpectedArgumentType) }
                // @Todo: change argument from Type to something that will also contain argument name and label
                // @Todo: type check arguments
                arguments.append(Value(name: argNameTok.value.value, exprType: .named(argTypeTok.value.value),
                                       startCursor: argNameTok.token.startCursor,
                                       endCursor: argTypeTok.token.endCursor))
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { throw error(em.procArgumentParentheses) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = .named(type.value) }
            else { throw error(em.procReturnTypeExpected) }
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
                throw error(em.procUndeclaredDirective, directiveToken.startCursor, directiveToken.endCursor)
            }
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { throw error(em.procForeignUnexpectedBody) }
            
            let procedureScope = globalScope.next()
            arguments.forEach { arg in
                let decl = VariableDeclaration(name: arg.name, exprType: arg.exprType,
                                               flags: [.isConstant], expression: arg)
                procedureScope.declarations[arg.name] = decl
            }
            
            let statements = try doStatements(in: procedureScope)
            scope = Code(statements)

            while let returnStat = firstNotMatchingReturnStatement(in: scope, to: returnType) {
                if let fixedExpr = convertExpression(returnStat.value, to: returnType) {
                    returnStat.value = fixedExpr
                    continue
                }
                throw error(em.returnTypeNotMatching(returnType, returnStat.value.exprType),
                             returnStat.value.startCursor, returnStat.value.endCursor)
            }
            
            if !(scope.statements.last is Return) {
                if returnType.equals(to: .void) { scope.statements.append(Return(value: VoidLiteral())) }
                else { throw error(em.procNotReturning) }
            }
        }
        else {
            throw error(em.procExpectedBody)
        }
        let procedure = ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope)
        let previousForceEntry = entry?.flags.contains(.main) ?? false
        if previousForceEntry && isForceEntry { throw error(em.procMainRedecl, start, end) }
        if name == "main" && entry == nil || isForceEntry {
            entry = procedure
            id = procName.value
        }
        if let e = verifyNameConflict(procedure) { throw error(e, start, end) }
        appendDeclaration(procedure, to: globalScope)
        procedure.startCursor = start
        procedure.endCursor = end
        return procedure
    }
    
    // MARK: - IF-ELSE -
    
    func doIf(in scope: Scope) throws -> Condition {
        let tok = token
        guard consumeKeyword(.if) else { report("can't call doIf without checking for keyword first") }
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        if hasParentheses {
            condition = try doExpression(in: scope, expectSemicolon: false)
            if !consumePunct(")") { throw error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(em.ifExpectedBrackets) }
        ifBody = try doStatements(in: scope.next())
        guard consumePunct("}") else { throw error(em.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { throw error(em.ifExpectedBrackets) }
            elseBody = try doStatements(in: scope.next())
            guard consumePunct("}") else { throw error(em.ifExpectedBrackets) }
        }
        let ifStatement = Condition(condition: condition, block: Code(ifBody), elseBlock: Code(elseBody),
                                    startCursor: tok.startCursor, endCursor: tok.endCursor)
        return ifStatement
    }
    
    // MARK: - WHILE LOOP -
    
    func matchWhile() -> Bool {
        (token.value as? Keyword) == .while
            || (token.value is Identifier // "label: while"
                && (peekNext()?.value as? Punctuator)?.value == ":"
                && (peekNext(index: 2)?.value as? Keyword) == .while)
    }
    
    func doWhile(in scope: Scope) throws -> WhileLoop {
        let start = token.startCursor
        let labelIdent = consumeIdent()
        let label = labelIdent?.value.value
        if labelIdent != nil {
            guard consumePunct(":") else { report("call matchWhile required before calling this") }
        }
        let end = token.endCursor
        guard consumeKeyword(.while) else { report("can't call doWhile without checking for keyword first") }
        if let labelIdent = labelIdent {
            if scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { throw error(em.loopLabelDuplicate, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        if hasParentheses {
            condition = try doExpression(in: scope, expectSemicolon: false)
            if !consumePunct(")") { throw error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(em.loopExpectedBrackets) }
        let loopBody = try doStatements(in: scope.next(as: ContextLoop(label: label)))
        guard consumePunct("}") else { throw error(em.loopExpectedBrackets) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(loopBody),
                                       startCursor: start, endCursor: end)
        return whileStatement
    }
    
    func doBreak(in scope: Scope) throws -> Break {
        let tok = token
        guard consumeKeyword(.break) else { report("can't call doBreak without checking for keyword first") }
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { throw error(em.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { throw error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { throw error(em.breakContext, tok.startCursor, tok.endCursor) }
        }
        let br = Break(userLabel: labelIdent?.value.value, startCursor: tok.startCursor, endCursor: tok.endCursor)
        return br
    }
    
    func doContinue(in scope: Scope) throws -> Continue {
        let tok = token
        guard consumeKeyword(.continue) else { report("can't call doContinue without checking for keyword first") }
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { throw error(em.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { throw error(em.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { throw error(em.continueContext, tok.startCursor, tok.endCursor) }
        }
        let cont = Continue(userLabel: labelIdent?.value.value, startCursor: tok.startCursor, endCursor: token.endCursor)
        return cont
    }
    
    // MARK: - EXPRESSIONS -
    
    /// `Binary` or `any single expression`
    func doExpression(in scope: Scope, expectSemicolon: Bool = true, _ priority: Int = 0) throws -> Expression {
        guard tokens.count > i else { throw error(em.unexpectedEndOfFile, lastToken.endCursor) }

        var left = try doExpr(in: scope)
        while let op = token.value as? Operator, let opPriority = precedence(of: op.value), opPriority >= priority {
            _ = consumeOperator()
            var right: Expression!
            right = try doExpression(in: scope, expectSemicolon: false, opPriority + 1)
    
            if !left.exprType.equals(to: right.exprType) {
                if let r = convertExpression(right, to: left.exprType) {
                    right = r
                }
                else if let l = convertExpression(left, to: right.exprType) {
                    left = l
                }
            }
            
            guard left.exprType.equals(to: right.exprType) else {
                throw error(em.binopArgTypeMatch(left.exprType, r: right.exprType), left.startCursor, right.endCursor)
            }
            guard isAccepting(op.value, argType: left.exprType) else {
                throw error(em.binopArgTypeSupport(op.value, t: left.exprType), left.startCursor, right.endCursor)
            }
            
            let type = returnType(ofBinaryOperation: op.value, arg: left.exprType)
            left = BinaryOperator(name: op.value, exprType: type, arguments: (left, right),
                                  startCursor: left.startCursor, endCursor: right.endCursor)
        }
        
        if expectSemicolon, !consumeSep(";") { throw error(em.expectedSemicolon) }
        return left
    }
    
    /// A single unit expression: `literal`, `value`, `procedure call`.
    func doExpr(in scope: Scope) throws -> Expression {
        let start = token.startCursor

        var arg: Expression!
        if consumePunct("(") {
            arg = try doExpression(in: scope, expectSemicolon: false)
            if !consumePunct(")") { throw error(em.ifExpectedBrackets) }
            return arg
        }
        else if let (opTok, op) = consumeOperator() { // unary operation
            arg = try doExpr(in: scope)
            
            let type = returnType(ofUnaryOperation: op.value, arg: arg.exprType)
            let op = UnaryOperator(name: op.value, exprType: type, argument: arg)
            op.startCursor = opTok.startCursor
            op.endCursor = opTok.endCursor
            return op
        }
        
        let expression: Expression
        switch token.value {
            
        case let keyword as Keyword:
            switch keyword {
            case .sizeof:
                let start = token.startCursor
                guard nextToken(), let typeIdent = consumeIdent() else {
                    throw error(em.sizeofExpectedType, token.startCursor, token.endCursor)
                }
                let type = Type.named(typeIdent.value.value)
                // @Todo: depend on this type to be resolved
                expression = SizeOf(type: type, startCursor: start, endCursor: typeIdent.token.endCursor)
            case .cast:
                let start = token.startCursor
                guard nextToken(), consumePunct("("), let typeIdent = consumeIdent(), consumePunct(")") else {
                    throw error(em.castExpectsTypeInBrackets, token.startCursor, token.endCursor)
                }
                let type = Type.named(typeIdent.value.value)
                // @Todo: depend on this type to be resolved
                let expr = try doExpression(in: scope, expectSemicolon: false)
                expression = UnaryOperator(name: "cast", exprType: type, argument: expr,
                                           startCursor: start, endCursor: expr.endCursor)
                
            default:
                print("Expression unknown: \(token)")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
            }
            
        case let literal as TokenLiteral:
            switch literal.value {
            case .int(let value): expression = IntLiteral(value: value)
            case .bool(let value): expression = IntLiteral(value: value ? 1 : 0, exprType: .bool)
            case .float(let value): expression = FloatLiteral(value: value)
            case .null: expression = NullLiteral(exprType: .unresolved)
            case .void: expression = VoidLiteral()
            case .string(let value):
                if scope === globalScope {
                    expression = StringLiteral(value: value)
                }
                else { // convert string literal to global constant
                    var decl: VariableDeclaration! = stringLiterals[value]
                    if decl == nil {
                        let count = stringLiterals.count
                        let id = "StringLiteral\(count)"
                        decl = VariableDeclaration(name: id, exprType: .string,
                                                   flags: .isConstant, expression: StringLiteral(value: value))
                        stringLiterals[value] = decl
                        statements.insert(decl, at: 0)
                    }
                    expression = Value(name: decl.name, exprType: .string)
                }
            }
            if !nextToken() { throw error(em.unexpectedEndOfFile) }
        case let identifier as Identifier:
            let tok = token
            if matchProcedureCall() {
                expression = try doProcedureCall(in: scope)
                break
            }
            
            if !nextToken() { throw error(em.unexpectedEndOfFile) }
            if matchMemberAccess() {
                var base: Expression = Value(name: identifier.value, exprType: .unresolved,
                                             startCursor: tok.startCursor, endCursor: tok.endCursor)
                // @Todo: resolve type of base
                while matchMemberAccess() {
                    base = try doMemberAccess(of: base, in: scope)
                }
                expression = base
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
                    else { throw error(em.assignPassedNotValue(statement), tok.startCursor, tok.endCursor) }
                }
            }
        case is Punctuator: throw error(em.expectedExpression)
        case is Separator: throw error(em.expectedExpression)
        default:
            print("Expression unknown: \(token)")
            throw error(em.notImplemented, token.startCursor, token.endCursor)
        }
        expression.startCursor = start
        expression.endCursor = lastToken.endCursor
        return expression
    }
    
    // MARK: - STATEMENTS -
    
    func doStatements(in scope: Scope) throws -> [Statement] {
        // body of: procedure, if-else, loop
        var statements: [Statement] = []
        loop: while tokens.count > i {
            switch token.value  {
            case let punct as Punctuator:
                if punct.value == "}" { // done with the scope
                    return statements
                }
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                switch keyword {
                case .func:
                    throw error(em.procNestedNotSupported, token.startCursor, token.endCursor)
                case .break:
                    let decl = try doBreak(in: scope)
                    statements.append(decl)
                    break loop
                case .continue:
                    let decl = try doContinue(in: scope)
                    statements.append(decl)
                    break loop
                case .if:
                    let decl = try doIf(in: scope)
                    statements.append(decl)
                    break loop
                default: break
                }
                
                if matchWhile() {
                    let decl = try doWhile(in: scope)
                    statements.append(decl)
                }
                else if consumeKeyword(.return) {
                    var returnExpression: Expression?
                    if !consumeSep(";") {
                        returnExpression = try doExpression(in: scope, expectSemicolon: false)
                    }
                    let end = returnExpression?.endCursor ?? lastToken.endCursor
                    let returnStatement = Return(
                        value: returnExpression ?? VoidLiteral(),
                        startCursor: lastToken.startCursor, endCursor: end)
                    statements.append(returnStatement)
                }
                else {
                    print("Unexpected keyword: \(keyword.rawValue)")
                    throw error(em.notImplemented, token.startCursor, token.endCursor)
                }
                
            case is Identifier: // @Clean: this is a copy from the main loop
                
                if matchProcedureCall() {
                    let decl = try doProcedureCall(in: scope)
                    statements.append(decl)
                    break
                }
                if matchWhile() {
                    let decl = try doWhile(in: scope)
                    statements.append(decl)
                    break
                }
                if matchVarDecl() {
                    let decl = try doVarDecl(in: scope)
                    statements.append(decl)
                    break
                }
                
                let assignmentReceiver = try matchAssignment(in: scope)
                if let base = assignmentReceiver {
                    let decl = try doAssign(to: base, in: scope)
                    statements.append(decl)
                    break
                }
                
                print("(statements loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
            case is Comment:
                if !nextToken() { break loop }
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop }}
                
            case is EOF:
                break loop
            default:
                print("(statements loop) Unexpected token\n\(token)\n")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
            }
        }
        return statements
    }
    
    func parse() throws -> Code {
        loop: while tokens.count > i {
            
            switch token.value  {
            case let keyword as Keyword:
                if keyword == .func {
                    let decl = try doProcDecl(in: globalScope)
                    statements.append(decl)
                    break
                }
                if keyword == .struct {
                    let decl = try doStructDecl()
                    statements.append(decl)
                    break
                }
                if keyword == .if { throw error(em.ifNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if matchWhile() { throw error(em.loopNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if keyword == .break { throw error(em.breakContext, token.startCursor, token.endCursor) }
                if keyword == .continue { throw error(em.continueContext, token.startCursor, token.endCursor) }
                if keyword == .fallthrough { throw error("@Todo: FALLTHROUGH ERROR MESSAGE", token.startCursor, token.endCursor) }

                print("Keyword \(keyword.rawValue) is not YET implemented.")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
                    
            case is Identifier:
                if matchWhile() { throw error(em.loopNotExpectedAtGlobalScope) }
                
                if matchVarDecl() {
                    let decl = try doVarDecl(in: globalScope)
                    statements.append(decl)
                    break
                }
                
                print("(main loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
            
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop } /* ignore */ }
                
            default: if !nextToken() { break loop }
            }
        }
        return Code(statements)
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
    
    var statements: [Statement] = []
    var stringLiterals: [String: VariableDeclaration] = [:]
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var globalScope = Scope() /// all declarations in global scope
    
    let em: ErrorMessage = ErrorMessage()
    var i = 0
    var token: Token
    var entry: ProcedureDeclaration?
}
