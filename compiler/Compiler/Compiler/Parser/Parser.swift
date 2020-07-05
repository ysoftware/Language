//
//  Parser.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

// Constants

extension Parser {

    // MARK: - TYPE -

    func matchType() -> Bool { token.value is Identifier }

    func doType(in scope: Scope) throws -> (type: Type, range: CursorRange) {
        guard let baseIdent = consumeIdent() else { throw error(em.expectedType(token), token.startCursor, token.endCursor) }

        var end = baseIdent.token.endCursor
        var solidTypes: [Type] = []

        if consumeOp("<") {
            while !consumeOp(">") {
                if solidTypes.count > 0, !consumeSep(",") {
                    throw error(em.structExpectedClosingTriangleBracket)
                }
                let (solidType, _) = try doType(in: scope)
                solidTypes.append(solidType)
            }
        }

        var type: Type
        let noPointerIdent = baseIdent.value.value.replacingOccurrences(of: "*", with: "")
        if solidTypes.isEmpty {
            if let alias = scope.declarations[noPointerIdent] as? TypealiasDeclaration { // generic type
                type = AliasType(name: alias.name)

                var p = "*"
                while (baseIdent.value.value.hasSuffix(p)) {
                    type = pointer(type)
                    p += "*"
                }
            }
            else {
                guard let resolvedType = resolveType(named: baseIdent.value.value)
                    else { throw error(em.expectedType(baseIdent.token)) }
                type = resolvedType
            }
        }
        else {
            type = StructureType(name: noPointerIdent, solidTypes: solidTypes)

            while consumeOp("*") {
                type = pointer(type)
            }
        }

        end = lastToken.endCursor
        let range = CursorRange(baseIdent.token.startCursor, end)
        return (type, range)
    }
    
    // MARK: - MEMBER ACCESS -
    
    func matchMemberAccess() -> Bool {
        (token.value as? Punctuator)?.value == "." && peekNext()?.value is Identifier
    }
    
    func doMemberAccess(of base: Expression, in scope: Scope) throws -> Expression {
        guard consumePunct(".") else { report("call matchMemberAccess required before calling this") }
        
        if let value = base as? Value, value.exprType.equals(to: UnresolvedType()) {
            if let decl = scope.declarations[value.name] as? VariableDeclaration {
                base.exprType = decl.exprType
            }
        }
        guard let memberIdent = consumeIdent() else {
            throw error(em.expectedMemberIdentifier, token.startCursor, token.endCursor)
        }
        let member = memberIdent.value.value
        let info = try resolveMemberTypeAndIndex(forName: member, of: base, in: scope)
        let access = MemberAccess(base: base, memberName: member, memderIndex: info.index, exprType: info.type,
                                  range: CursorRange(base.range.start, memberIdent.token.endCursor))
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
            
            let decl = resolveVarDecl(named: identifier.value, in: scope)
            let exprType = decl?.exprType ?? UnresolvedType()
            let id = decl?.id ?? Scope.unresolvedId
            var base: Expression = Value(name: identifier.value, id: id, exprType: exprType,
                                         range: token.range)
            if !nextToken() { throw error(em.unexpectedEndOfFile) }
            while matchMemberAccess() {
                base = try doMemberAccess(of: base, in: scope)
            }
            // @Todo: check root member access base existence
            
            guard consumeOp("=") else { throw error(em.unexpectedMemberAccess, base.range) }
            return base
        }
        
        return nil
    }
    
    func doAssign(to rValue: Ast, in scope: Scope) throws -> Assignment {
        let start = rValue.range.start
        
        var expectingType: Type!
        if let expr = rValue as? Expression {
            expectingType = expr.exprType
        }
        
        var expr = try doExpression(in: scope)
        if !expectingType.equals(to: UnresolvedType()) {
            // @Todo: resolve expression type

            if !expr.exprType.equals(to: expectingType) {
                guard let converted = convertExpression(expr, to: expectingType) else {
                    throw error(em.assignTypeMismatch(expectingType, expr.exprType), expr.range)
                }
                expr = converted
            }
        }
        
        let assign = Assignment(
            receiver: rValue, expression: expr, range: CursorRange(start, expr.range.end))
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

        // @Todo: check that identifier doesn't have forbidden symbols like '*'

        var expr: Expression?
        var flags: VariableDeclaration.Flags = []

        var declaredType: (type: Type, range: CursorRange)? = nil
        if matchType() {
            declaredType = try doType(in: scope)
        }

        var expectingExpression = true
        let end = token.endCursor
        
        if consumePunct(":") { flags.insert(.isConstant) }
        else if !consumeOp("=") { expectingExpression = false }
        
        if expectingExpression {
            expr = try doExpression(in: scope)
            if let exprType = expr?.exprType, let declaredType = declaredType {
                if let converted = convertExpression(expr!, to: declaredType.type) {
                    expr = converted
                }
                else if !declaredType.type.equals(to: exprType) {
                    throw error(em.varDeclTypeMismatch(exprType, declaredType.type),
                                declaredType.range.start, declaredType.range.end)
                }
            }
        }
        else if !consumeSep(";") { throw error(em.expectedSemicolon) }

        // variable type inference
        let type: Type
        if let t = expr?.exprType {
            type = t
        }
        else if let declType = declaredType?.type {
            type = declType
        }
        else { throw error(em.varDeclRequiresType) } // @Todo: check cursors and if this error is even valid
        
        let name = identifier.value.value
        let id = "\(scope.id)\(name)"
        let varDecl = VariableDeclaration(
            name: name, id: id, exprType: type, flags: flags, expression: expr,
            range: CursorRange(start, end))
        
        // @Todo: check that dependency is added correctly for unresolved
        // we're supposed to add this decl as a dependant on the expression
        
        try verifyNameConflict(varDecl, in: scope)
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

        // parse generic types here
        let structScope = nextScope(from: globalScope)
        var genericTypes: [String] = []
        if consumeOp("<") {
            while !consumeOp(">") {
                if genericTypes.count > 0, !consumeSep(",") { throw error(em.structExpectedClosingTriangleBracket) }
                guard let typeIdent = consumeIdent() else { throw error(em.structExpectedGenericType) }
                genericTypes.append(typeIdent.value.value)
                structScope.declarations[typeIdent.value.value] = TypealiasDeclaration(name: typeIdent.value.value)
            }
        }

        guard consumePunct("{")
            else { throw error(em.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        while tokens.count > i {
            if matchVarDecl() {
                let member = try doVarDecl(in: structScope)
                members.append(member)
            }
            else {
                if consumePunct("}") { break }
                else { throw error(em.structExpectedBracketsEnd) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, members: members, genericTypes: genericTypes,
                                           range: CursorRange(start, end))
        try verifyNameConflict(structDecl)
        appendDeclaration(structDecl, to: globalScope)
        return structDecl
    }
    
    // MARK: - PROCEDURE CALL -
    
    func matchProcCall() -> Bool {
        token.value is Identifier && (peekNext()?.value as? Punctuator)?.value == "("
    }
    
    func doProcCall(in scope: Scope) throws -> ProcedureCall {
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
        var returnType: Type = UnresolvedType()
        
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
                            declArgument.exprType.typeName, arguments[i].exprType.typeName), arguments[i].range)
                    }
                }
            }
            else { throw error(em.callNotProcedure, identToken.startCursor, identToken.endCursor) }
        }

        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments, range: CursorRange(start, end))
        if !returnType.isResolved {
            appendUnresolved(returnType.typeName, call)
        }
        return call
    }
    
    // MARK: - PROCEDURE DECLARATION -

    func doProcDecl(in scope: Scope) throws -> ProcedureDeclaration {
        let start = token.startCursor
        guard consumeKeyword(.func) else { report("can't call doProcDecl without checking for keyword first") }
        guard let procNameIdent = consumeIdent()?.value else {
            throw error(em.procExpectedName(token), token.startCursor, token.endCursor)
        }
        guard consumePunct("(") else { throw error(em.expectedParentheses) }
        scopeCounter = 0 // reset scope counter
        let end = lastToken.endCursor
        let returnType: Type
        let procName = procNameIdent.value
        var procId = procName // @Todo: use with generics
        var arguments: [Value] = []
        var flags = ProcedureDeclaration.Flags()
        var code: Code = .empty
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
                guard let argNameTok = consumeIdent() else {
                    throw error(em.procExpectedArgumentName, token.startCursor, token.endCursor)
                }
                guard consumePunct(":") else { throw error(em.procExpectedArgumentType) }
                let argType = try doType(in: scope)
                // @Todo: change argument from Type to something that will also contain argument name and label
                let argName = argNameTok.value.value
                let argId = "\(procId)_arg_\(argName)"
                let value = Value(name: argName, id: argId, exprType: argType.type, range: argType.range)
                arguments.append(value)
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { throw error(em.procArgumentParentheses) }
        if consumePunct("->") {
            if let type = consume(Identifier.self)?.value { returnType = typeNamed(type.value) }
            else { throw error(em.procReturnTypeExpected) }
        }
        else { returnType = void }
        if let (directiveToken, directive) = consume(Directive.self) {
            switch directive.value {
            case "foreign":
                flags.insert(.isForeign)
                procId = procName
            case "main":
                flags.insert(.main)
                isForceEntry = true
            default:
                throw error(em.procUndeclaredDirective, directiveToken.startCursor, directiveToken.endCursor)
            }
        }
        else if consumePunct("{") {
            if flags.contains(.isForeign) { throw error(em.procForeignUnexpectedBody) }
            
            let procedureScope = nextScope(from: globalScope)
            
            // CREATE PROCEDURE-LOCAL VARIABLES FROM ARGUMENTS
            arguments.forEach { arg in
                let argId = "\(procId)_arg_\(arg.name)"
                let decl = VariableDeclaration(name: arg.name, id: argId, exprType: arg.exprType,
                                               flags: [.isConstant], expression: arg)
                procedureScope.declarations[arg.name] = decl
            }
            
            let statements = try doStatements(in: procedureScope)
            code = Code(statements)

            while let returnStat = firstNotMatchingReturnStatement(in: code, to: returnType) {
                if let fixedExpr = convertExpression(returnStat.value, to: returnType) {
                    returnStat.value = fixedExpr
                    continue
                }
                throw error(em.returnTypeNotMatching(returnType, returnStat.value.exprType), returnStat.range)
            }
            
            if !(code.statements.last is Return) {
                if returnType.equals(to: void) { code.statements.append(Return(value: VoidLiteral())) }
                else { throw error(em.procNotReturning) }
            }
        }
        else {
            throw error(em.procExpectedBody)
        }
        let procedure = ProcedureDeclaration(
            id: procId, name: procName, arguments: arguments,
            returnType: returnType, flags: flags, scope: code, range: CursorRange(start, end))

        let previousForceEntry = entry?.flags.contains(.main) ?? false
        if previousForceEntry && isForceEntry { throw error(em.procMainRedecl, start, end) }
        if procName == "main" && entry == nil || isForceEntry {
            entry = procedure
            procId = procName
        }
        try verifyNameConflict(procedure)
        appendDeclaration(procedure, to: globalScope)
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
            if condition.exprType.equals(to: UnresolvedType()) {
                // @Todo: depend if on condition
            }
            else if !condition.exprType.equals(to: bool) {
                throw error(em.conditionTypeMismatch(condition.exprType), condition.range)
            }
            if !consumePunct(")") { throw error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(em.ifExpectedBrackets) }
        ifBody = try doStatements(in: nextScope(from: scope))
        guard consumePunct("}") else { throw error(em.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { throw error(em.ifExpectedBrackets) }
            elseBody = try doStatements(in: nextScope(from: scope))
            guard consumePunct("}") else { throw error(em.ifExpectedBrackets) }
        }
        let ifStatement = Condition(condition: condition, block: Code(ifBody), elseBlock: Code(elseBody),
                                    range: tok.range)
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
            if condition.exprType.equals(to: UnresolvedType()) {
                // @Todo: depend while on condition
            }
            else if !condition.exprType.equals(to: bool) {
                throw error(em.conditionTypeMismatch(condition.exprType), condition.range)
            }
            if !consumePunct(")") { throw error(em.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(em.loopExpectedBrackets) }
        let loopBody = try doStatements(in: nextScope(from: scope, as: ContextLoop(label: label)))
        guard consumePunct("}") else { throw error(em.loopExpectedBrackets) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(loopBody),
                                       range: CursorRange(start, end))
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
        let br = Break(userLabel: labelIdent?.value.value, range: tok.range)
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
        let cont = Continue(userLabel: labelIdent?.value.value, range: tok.range)
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

            let range = CursorRange(left.range.start, right.range.end)
            guard left.exprType.equals(to: right.exprType) else {
                throw error(em.binopArgTypeMatch(left.exprType, r: right.exprType), range)
            }
            guard isAccepting(op.value, argType: left.exprType) else {
                throw error(em.binopArgTypeSupport(op.value, t: left.exprType), range)
            }
            
            let type = returnType(ofBinaryOperation: op.value, arg: left.exprType)
            left = BinaryOperator(name: op.value, exprType: type, arguments: (left, right), range: range)
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
            let op = UnaryOperator(name: op.value, exprType: type, argument: arg, range: opTok.range)
            return op
        }
        
        let expression: Expression
        switch token.value {
            
        case let keyword as Keyword:
            guard nextToken() else { throw error(em.unexpectedEndOfFile) }
            switch keyword {
            case .sizeof:
                let start = token.startCursor
                let (type, range) = try doType(in: scope)
                // @Todo: depend on this type to be resolved
                expression = SizeOf(type: type, range: CursorRange(start, range.end))
            case .new:
                let type = try doType(in: scope)
                let new = New(type: type.type, range: type.range)
                expression = new
            case .cast:
                let start = token.startCursor
                guard consumePunct("(") else {
                    throw error(em.castExpectsTypeInBrackets, token.startCursor, token.endCursor)
                }
                let type = try doType(in: scope)
                guard consumePunct(")") else {
                    throw error(em.castExpectsTypeInBrackets, token.startCursor, token.endCursor)
                }
                // @Todo: depend on this type to be resolved
                let expr = try doExpression(in: scope, expectSemicolon: false)
                expression = UnaryOperator(name: "cast", exprType: type.type, argument: expr,
                                           range: CursorRange(start, expr.range.end))
                
            default:
                print("Expression unknown: \(token)")
                throw error(em.notImplemented, token.startCursor, token.endCursor)
            }
            
        case let literal as TokenLiteral:
            switch literal.value {
            case .int(let value): expression = IntLiteral(value: value)
            case .bool(let value): expression = IntLiteral(value: value ? 1 : 0, exprType: bool)
            case .float(let value): expression = FloatLiteral(value: value)
            case .null: expression = NullLiteral(exprType: UnresolvedType())
            case .void: expression = VoidLiteral()
            case .string(let value):
                if scope === globalScope {
                    expression = StringLiteral(value: value)
                }
                else { // @Todo: convert string literal to global constant
                    let count = stringLiterals.count
                    let id = "\(scope.id)StringLiteral\(count)"
                    var decl: VariableDeclaration! = stringLiterals[id]
                    if decl == nil {
                        decl = VariableDeclaration(name: id, id: id, exprType: string,
                                                   flags: .isConstant, expression: StringLiteral(value: value))
                        stringLiterals[id] = decl
                        statements.insert(decl, at: 0)
                    }
                    expression = Value(name: decl.name, id: id, exprType: string)
                }
            }
            if !nextToken() { throw error(em.unexpectedEndOfFile) }
        case let identifier as Identifier:
            let tok = token
            if matchProcCall() {
                expression = try doProcCall(in: scope)
                break
            }
            
            if !nextToken() { throw error(em.unexpectedEndOfFile) }

            let decl = resolveVarDecl(named: identifier.value, in: scope)
            let exprType = decl?.exprType ?? UnresolvedType()
            let id = decl?.id ?? Scope.unresolvedId
            
            if matchMemberAccess() {
                var base: Expression = Value(name: identifier.value, id: id, exprType: exprType, range: tok.range)
                
                // @Todo: else add to global dependencies
                
                while matchMemberAccess() {
                    base = try doMemberAccess(of: base, in: scope)
                }
                expression = base
            }
            else {
                expression = Value(name: identifier.value, id: id, exprType: exprType)
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
        expression.range = CursorRange(start, lastToken.endCursor)
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
                throw error(em.unexpectedToken(punct.value), token.startCursor, token.endCursor)
                
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                switch keyword {
                case .func:
                    throw error(em.procNestedNotSupported, token.startCursor, token.endCursor)
                case .break:
                    let decl = try doBreak(in: scope)
                    statements.append(decl)
                    continue loop
                case .continue:
                    let decl = try doContinue(in: scope)
                    statements.append(decl)
                    continue loop
                case .if:
                    let decl = try doIf(in: scope)
                    statements.append(decl)
                    continue loop
                case .free:
                    let start = token.startCursor
                    guard nextToken() else { throw error(em.unexpectedEndOfFile) }
                    let expr = try doExpression(in: scope, expectSemicolon: true)
                    let type = resolveType(of: expr)
                    guard type is PointerType else { throw error(em.freeExpectsPointer) }
                    let free = Free(expression: expr, range: CursorRange(start, expr.range.end))
                    statements.append(free)
                    continue loop
                default:
                    break
                }
                
                if matchWhile() {
                    let decl = try doWhile(in: scope)
                    statements.append(decl)
                }
                else if consumeKeyword(.return) {
                    var returnExpression: Expression?
                    if !consumeSep(";") {
                        returnExpression = try doExpression(in: scope, expectSemicolon: false)
                        // @Todo: should be expectSemicolon: true?
                        // are we even eating a semicolon?
                    }
                    let end = returnExpression?.range.end ?? lastToken.range.end
                    let returnStatement = Return(
                        value: returnExpression ?? VoidLiteral(),
                        range: CursorRange(lastToken.startCursor, end))
                    statements.append(returnStatement)
                }
                else {
                    throw error(em.unexpectedToken(keyword.rawValue), token.startCursor, token.endCursor)
                }
                
            case is Identifier: // @Clean: this is a copy from the main loop
                
                if matchProcCall() {
                    let decl = try doProcCall(in: scope)
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
                
                throw error(em.unexpectedToken("\(token)"), token.startCursor, token.endCursor)
            case is Comment:
                if !nextToken() { break loop }
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop }}
                
            case is EOF:
                break loop
            default:
                throw error(em.unexpectedToken("\(token)"), token.startCursor, token.endCursor)
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
    var stringLiterals: [String: VariableDeclaration] = [:] /// id : VarDecl*
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var globalScope = Scope(id: Scope.globalId) /// all declarations in global scope
    
    var scopeCounter = 0
    let em: ErrorMessage = ErrorMessage()
    var i = 0
    var token: Token
    var entry: ProcedureDeclaration?
}
