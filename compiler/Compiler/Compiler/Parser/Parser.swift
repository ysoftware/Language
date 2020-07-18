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
        guard let baseIdent = consumeIdent() else { throw error(ParserMessage.expectedType(token), token.startCursor, token.endCursor) }

        var solidTypes: [Type] = []
        if consumeOp("<") {
            while !consumeOp(">") {
                if solidTypes.count > 0, !consumeSep(",") {
                    throw error(ParserMessage.structExpectedClosingTriangleBracket)
                }
                let (solidType, _) = try doType(in: scope)
                solidTypes.append(solidType)
            }
        }

        var type: Type
        let noPointerIdent = baseIdent.value.value.replacingOccurrences(of: "*", with: "") // @Todo: this is weird, check this
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
                let noPointerType = typeNamed(baseIdent.value.value).getValueType().typeName
                guard genericDeclarations[noPointerType] == nil else {
                    throw error(ParserMessage.structShouldBeGeneric(noPointerType), baseIdent.token.range)
                }

                type = typeNamed(baseIdent.value.value)
                if type is StructureType {

                    if let decl = globalScope.declarations[baseIdent.value.value] {
                        guard let structure = decl as? StructDeclaration else {
                            throw error(ParserMessage.expectedType(baseIdent.token))
                        }
                        type = StructureType(name: structure.name)
                    } else {
                        type = UnresolvedType()
                    }
                }
            }
        }
        else { // GENERIC TYPE
            type = StructureType(name: noPointerIdent, solidTypes: solidTypes)
            while consumeOp("*") {
                type = pointer(type)
            }
        }

        let range = CursorRange(baseIdent.token.startCursor, lastToken.endCursor)
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
            throw error(ParserMessage.expectedMemberIdentifier, token.startCursor, token.endCursor)
        }
        let member = memberIdent.value.value
        let info = try resolveMemberTypeAndIndex(forName: member, of: base, in: scope, memberRange: memberIdent.token.range)
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
                else { throw error(ParserMessage.assignUndeclared(identifier.value), token.startCursor, token.endCursor) }
            guard let varDecl = ast as? VariableDeclaration
                else { throw error(ParserMessage.assignPassedNotValue(ast), token.startCursor, token.endCursor) }
            guard !varDecl.flags.contains(.isConstant)
                else { throw error(ParserMessage.assignConst(identifier.value), token.startCursor, token.endCursor) }
            
            let decl = resolveVarDecl(named: identifier.value, in: scope)
            let exprType = decl?.exprType ?? UnresolvedType()
            let id = decl?.id ?? Scope.unresolvedId
            var base: Expression = Value(name: identifier.value, id: id, exprType: exprType,
                                         range: token.range)
            if !nextToken() { throw error(ParserMessage.unexpectedEndOfFile) }
            while matchMemberAccess() {
                base = try doMemberAccess(of: base, in: scope)
            }
            // @Todo: check root member access base existence
            
            guard consumeOp("=") else { throw error(ParserMessage.unexpectedMemberAccess, base.range) }
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
                guard let converted = try convertExpression(expr, to: expectingType) else {
                    throw error(ParserMessage.assignTypeMismatch(expectingType, expr.exprType), expr.range)
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
                if let converted = try convertExpression(expr!, to: declaredType.type) {
                    expr = converted
                }
                else if !declaredType.type.equals(to: exprType) {
                    throw error(ParserMessage.varDeclTypeMismatch(exprType, declaredType.type),
                                declaredType.range.start, declaredType.range.end)
                }
            }
        }
        else if !consumeSep(";") { throw error(ParserMessage.expectedSemicolon) }

        // variable type inference
        let type: Type
        if let t = expr?.exprType {
            type = t
        }
        else if let declType = declaredType?.type {
            type = declType
        }
        else { throw error(ParserMessage.varDeclRequiresType) } // @Todo: check cursors and if this error is even valid

        if let structType = type.getValueType() as? StructureType {
            try solidifyStructure(type: structType)
        }

        let name = identifier.value.value
        let id = "\(scope.id)\(name)"
        let varDecl = VariableDeclaration(
            name: name, id: id, exprType: type, flags: flags, expression: expr,
            range: CursorRange(start, end), ood: order())
        
        // @Todo: check that dependency is added correctly for unresolved
        // we're supposed to add this decl as a dependant on the expression

        try verifyNameConflict(varDecl, in: scope)
        scope.declarations[varDecl.name] = varDecl
        return varDecl
    }
    
    // MARK: - STRUCT DECLARATION -

    func doStructDecl() throws {
        let start = token.startCursor
        guard consumeKeyword(.struct) else { report("can't call doStructDecl without checking for keyword first") }
        guard let name = consumeIdent()?.value
            else { throw error(ParserMessage.structExpectedName) }
        let end = token.endCursor

        // parse generic types here
        let structScope = nextScope(from: globalScope)
        var genericTypes: [String] = []
        if consumeOp("<") {
            while !consumeOp(">") {
                if genericTypes.count > 0, !consumeSep(",") { throw error(ParserMessage.structExpectedClosingTriangleBracket) }
                guard let typeIdent = consumeIdent() else { throw error(ParserMessage.structExpectedGenericType) }
                genericTypes.append(typeIdent.value.value)
                structScope.declarations[typeIdent.value.value] = TypealiasDeclaration(name: typeIdent.value.value)
            }
        }

        guard consumePunct("{")
            else { throw error(ParserMessage.structExpectedBrackets) }
        var members: [VariableDeclaration] = []
        while tokens.count > i {
            if matchVarDecl() {
                let member = try doVarDecl(in: structScope)
                members.append(member)
            }
            else {
                if consumePunct("}") { break }
                else { throw error(ParserMessage.structExpectedBracketsEnd) }
            }
        }
        let structDecl = StructDeclaration(name: name.value, id: name.value, members: members,
                                           range: CursorRange(start, end), ood: order())
        try verifyNameConflict(structDecl)

        if genericTypes.isEmpty {
            globalScope.declarations[structDecl.name] = structDecl
            structureDeclarations[structDecl.name] = structDecl
        }
        else {
            genericDeclarations[structDecl.name] = (structDecl, genericTypes)
        }

        for member in members {
            if let structType = member.exprType.getValueType() as? StructureType {
                try solidifyStructure(type: structType)
            }
        }
    }
    
    // MARK: - PROCEDURE CALL -
    
    func matchProcCall() -> Bool {
        token.value is Identifier
            && ((peekNext()?.value as? Punctuator)?.value == "(" || (peekNext()?.value as? Operator)?.value == "<")
    }
    
    func doProcCall(in scope: Scope) throws -> ProcedureCall {
        let start = token.startCursor
        guard let (identToken, name) = consumeIdent()
            else { report("call matchProcedureCall required before calling this") }

        var solidTypes: [Type] = []
        if consumeOp("<") {
            while !consumeOp(">") {
                if solidTypes.count > 0, !consumeSep(",") {
                    throw error(ParserMessage.structExpectedClosingTriangleBracket)
                }
                let (solidType, _) = try doType(in: scope)
                solidTypes.append(solidType)
            }
        }

        var arguments: [Expression] = []
        guard consumePunct("(") else { throw error(ParserMessage.callExpectedOpenParentheses, token.range) }
        while tokens.count > i { // PROCEDURE CALL ARGUMENTS
            if (token.value as? Punctuator)?.value == ")" { break }
            let arg = try doExpression(in: scope, expectSemicolon: false)
            arguments.append(arg)
            if !consumeSep(",") { break }
        }
        guard consumePunct(")") else { throw error(ParserMessage.callExpectedClosingParentheses,
                                                    lastToken.endCursor.advancingCharacter()) }
        let range = CursorRange(start, lastToken.endCursor)
        var returnType: Type = UnresolvedType()

        let foundDecl = scope.declarations[name.value] ?? internalProcedures.first(where: { $0.name == name.value })

        if let statement = foundDecl { // else - proceed
            guard let procDecl = statement as? ProcedureDeclaration
                else { throw error(ParserMessage.callNotProcedure, identToken.startCursor, identToken.endCursor) }
            returnType = procDecl.returnType

            var argumentTypes: [Type] = []
            for i in 0..<procDecl.arguments.count {
                let arg = procDecl.arguments[i]
                let solidType = typeResolvingAliases(from: arg.exprType, declName: procDecl.name, solidTypes: solidTypes)
                argumentTypes.append(solidType)
            }

            let minArgWithoutVararg = argumentTypes.count - (procDecl.flags.contains(.isVarargs) ? 1 : 0)
            guard arguments.count >= minArgWithoutVararg else {
                throw error(ParserMessage.callArgumentsCount(argumentTypes.count, arguments.count), range)
            }
            for i in 0..<arguments.count {
                guard argumentTypes.count > i || procDecl.flags.contains(.isVarargs) else {
                    if procDecl.flags.contains(.isVarargs) {
                        throw error(ParserMessage.callArgumentsVarCount(argumentTypes.count, arguments.count), range)
                    }
                    else {
                        throw error(ParserMessage.callArgumentsCount(argumentTypes.count, arguments.count), range)
                    }
                }
                let declArgument = argumentTypes.count > i ? argumentTypes[i] : argumentTypes.last!

                // @Todo: check that dependency is added correctly for unresolved
                if !declArgument.isResolved {
                    arguments[i].exprType = argumentTypes[i]// resolveType(of: declArgument)
                }
                else if !declArgument.equals(to: arguments[i].exprType) {
                    throw error(ParserMessage.callArgumentTypeMismatch(
                        declArgument.typeName, arguments[i].exprType.typeName), arguments[i].range)
                }
            }
        }
        else if let (genericDecl, genericTypes) = genericDeclarations[name.value] {
            guard let genericProc = genericDecl as? ProcedureDeclaration else {
                throw error(ParserMessage.callNotProcedure, range)
            }
            solidifyProcedure(genericProc, genericTypes: genericTypes, solidTypes: solidTypes)
            returnType = genericProc.returnType
        }

        let call = ProcedureCall(name: name.value, exprType: returnType, arguments: arguments,
                                 solidTypes: solidTypes, range: range)
        if !returnType.isResolved {
            appendUnresolved(returnType.typeName, call)
        }
        return call
    }
    
    // MARK: - PROCEDURE DECLARATION -

    func doProcDecl() throws {
        let start = token.startCursor
        guard consumeKeyword(.func) else { report("can't call doProcDecl without checking for keyword first") }
        guard let procNameIdent = consumeIdent()?.value else {
            throw error(ParserMessage.procExpectedName(token), token.startCursor, token.endCursor)
        }

        let procedureScope = nextScope(from: globalScope)
        var genericTypeIdents: [Token] = [] // PROCEDURE GENERIC TYPES
        if consumeOp("<") {
            while !consumeOp(">") {
                if genericTypeIdents.count > 0, !consumeSep(",") { throw error(ParserMessage.structExpectedClosingTriangleBracket) }
                guard let typeIdent = consumeIdent() else { throw error(ParserMessage.structExpectedGenericType) }
                genericTypeIdents.append(typeIdent.token)
                procedureScope.declarations[typeIdent.value.value] = TypealiasDeclaration(name: typeIdent.value.value)
            }
        }
        var unusedGenericTypes = genericTypeIdents

        guard consumePunct("(") else { throw error(ParserMessage.expectedParentheses) }
        scopeCounter = 0 // reset scope counter
        let end = lastToken.endCursor
        let returnType: Type
        let procName = procNameIdent.value
        var procId = procName // @Todo: use with generics
        var arguments: [Value] = []
        var flags = ProcedureDeclaration.Flags()
        var code: Code = .empty
        var isForceEntry = false

        func useType(_ type: Type) {
            for (i, _) in unusedGenericTypes.enumerated().reversed() {
                if type.typeName.contains((unusedGenericTypes[i].value as! Identifier).value) {
                    unusedGenericTypes.remove(at: i)
                }
            }
        }

        while tokens.count > i { // PROCEDURE ARGUMENTS DECLARATION
            if (token.value as? Punctuator)?.value == ")" { break }
            if consumePunct("...") {
                if arguments.isEmpty { throw error(ParserMessage.procExpectedArgumentBeforeVarargs,
                                                   tokens[i-2].endCursor.advancingCharacter()) }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard let argNameTok = consumeIdent() else {
                    throw error(ParserMessage.procExpectedArgumentName, token.startCursor, token.endCursor)
                }
                guard consumePunct(":") else { throw error(ParserMessage.procExpectedArgumentType) }
                let argType = try doType(in: procedureScope)
                // @Todo: change argument from Type to something that will also contain argument name and label
                let argName = argNameTok.value.value
                let argId = "\(procId)_arg_\(argName)"
                let value = Value(name: argName, id: argId, exprType: argType.type, range: argType.range)
                arguments.append(value)

                useType(argType.type)
            }
            if !consumeSep(",") { break }
        }
        if !consumePunct(")") { throw error(ParserMessage.procArgumentParentheses) }
        if consumePunct("->") {
            returnType = try doType(in: procedureScope).type
            useType(returnType)
        }
        else { returnType = void }

        guard unusedGenericTypes.isEmpty else {
            throw error(ParserMessage.unusedGenericType((unusedGenericTypes[0].value as! Identifier).value), unusedGenericTypes[0].range)
        }

        while let (directiveToken, directive) = consume(Directive.self) {
            switch directive.value {
            case "foreign":
                guard !flags.contains(.isForeign) else { throw error(ParserMessage.procDirectiveDuplicate, directiveToken.range) }
                guard !flags.contains(.main) else { throw error(ParserMessage.procDirectiveConflict("#main", "#foreign"), directiveToken.range) }
                flags.insert(.isForeign)
                procId = procName
            case "main":
                guard !flags.contains(.isForeign) else { throw error(ParserMessage.procDirectiveConflict("#foreign", "#main"), directiveToken.range) }
                guard !flags.contains(.main) else { throw error(ParserMessage.procDirectiveDuplicate, directiveToken.range) }
                flags.insert(.main)
                isForceEntry = true
                let previousForceEntry = entry?.flags.contains(.main) ?? false
                if previousForceEntry && isForceEntry { throw error(ParserMessage.procMainRedecl, directiveToken.range) }
            default:
                throw error(ParserMessage.procUndeclaredDirective, directiveToken.startCursor, directiveToken.endCursor)
            }
        }

        if consumePunct("{") {
            if flags.contains(.isForeign) { throw error(ParserMessage.procForeignUnexpectedBody) }

            // CREATE PROCEDURE-LOCAL VARIABLES FROM ARGUMENTS
            arguments.forEach { arg in
                let argId = "\(procId)_arg_\(arg.name)"
                let decl = VariableDeclaration(name: arg.name, id: argId, exprType: arg.exprType,
                                               flags: [.isConstant], expression: arg, ood: order())
                procedureScope.declarations[arg.name] = decl
            }

            let statements = try doStatements(in: procedureScope)
            code = Code(statements)

            while let returnStat = firstNotMatchingReturnStatement(in: code, to: returnType) {
                if let fixedExpr = try convertExpression(returnStat.value, to: returnType) {
                    returnStat.value = fixedExpr
                    continue
                }
                throw error(ParserMessage.returnTypeNotMatching(returnType, returnStat.value.exprType), returnStat.range)
            }
            
            if !(code.statements.last is Return) {
                if returnType.equals(to: void) { code.statements.append(Return(value: VoidLiteral())) }
                else { throw error(ParserMessage.procNotReturning) }
            }
        }
        else if !flags.contains(.isForeign) {
            throw error(ParserMessage.procExpectedBody)
        }

        let genericTypes = genericTypeIdents.map { ($0.value as! Identifier).value }
        let procedure = ProcedureDeclaration(
            id: procId, name: procName, arguments: arguments, returnType: returnType, flags: flags,
            scope: code, range: CursorRange(start, end), ood: order())

        if procName == "main" && entry == nil || isForceEntry {
            entry = procedure
            procId = procName
        }

        try verifyNameConflict(procedure)

        if genericTypes.isEmpty {
            globalScope.declarations[procedure.name] = procedure
            procedureDeclarations[procedure.name] = procedure
        }
        else {
            genericDeclarations[procedure.name] = (procedure, genericTypes)
        }
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
                throw error(ParserMessage.conditionTypeMismatch(condition.exprType), condition.range)
            }
            if !consumePunct(")") { throw error(ParserMessage.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(ParserMessage.ifExpectedBrackets) }
        ifBody = try doStatements(in: nextScope(from: scope))
        guard consumePunct("}") else { throw error(ParserMessage.ifExpectedBrackets) }
        if consumeKeyword(.else) {
            if !consumePunct("{") { throw error(ParserMessage.ifExpectedBrackets) }
            elseBody = try doStatements(in: nextScope(from: scope))
            guard consumePunct("}") else { throw error(ParserMessage.ifExpectedBrackets) }
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
            { throw error(ParserMessage.loopLabelDuplicate, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        let hasParentheses = consumePunct("(")
        var condition: Expression!
        if hasParentheses {
            condition = try doExpression(in: scope, expectSemicolon: false)
            if condition.exprType.equals(to: UnresolvedType()) {
                // @Todo: depend while on condition
            }
            else if !condition.exprType.equals(to: bool) {
                throw error(ParserMessage.conditionTypeMismatch(condition.exprType), condition.range)
            }
            if !consumePunct(")") { throw error(ParserMessage.expectedParentheses) }
        }
        // @Todo: match condition type to bool (make the matching procedure)
        if !consumePunct("{") { throw error(ParserMessage.loopExpectedBrackets) }
        let loopBody = try doStatements(in: nextScope(from: scope, as: ContextLoop(label: label)))
        guard consumePunct("}") else { throw error(ParserMessage.loopExpectedBrackets) }
        let whileStatement = WhileLoop(userLabel: label, condition: condition, block: Code(loopBody),
                                       range: CursorRange(start, end))
        return whileStatement
    }
    
    func doBreak(in scope: Scope) throws -> Break {
        let tok = token
        guard consumeKeyword(.break) else { report("can't call doBreak without checking for keyword first") }
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { throw error(ParserMessage.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { throw error(ParserMessage.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { throw error(ParserMessage.breakContext, tok.startCursor, tok.endCursor) }
        }
        let br = Break(userLabel: labelIdent?.value.value, range: tok.range)
        return br
    }
    
    func doContinue(in scope: Scope) throws -> Continue {
        let tok = token
        guard consumeKeyword(.continue) else { report("can't call doContinue without checking for keyword first") }
        let labelIdent = consumeIdent()
        guard consumeSep(";") else { throw error(ParserMessage.expectedSemicolon) }
        if let labelIdent = labelIdent {
            if !scope.contexts.contains(where: { ($0 as? ContextLoop)?.label == labelIdent.value.value })
            { throw error(ParserMessage.loopLabelNotFound, labelIdent.token.startCursor, labelIdent.token.endCursor) }
        }
        else {
            if nil == scope.contexts.last(where: { $0 is ContextLoop })
                { throw error(ParserMessage.continueContext, tok.startCursor, tok.endCursor) }
        }
        let cont = Continue(userLabel: labelIdent?.value.value, range: tok.range)
        return cont
    }
    
    // MARK: - EXPRESSIONS -
    
    /// `Binary` or `any single expression`
    func doExpression(in scope: Scope, expectSemicolon: Bool = true, _ priority: Int = 0) throws -> Expression {
        guard tokens.count > i else { throw error(ParserMessage.unexpectedEndOfFile, lastToken.endCursor) }

        var left = try doExpr(in: scope)
        while let op = token.value as? Operator, let opPriority = precedence(of: op.value), opPriority >= priority {
            _ = consumeOperator()
            var right: Expression!
            right = try doExpression(in: scope, expectSemicolon: false, opPriority + 1)
    
            if !left.exprType.equals(to: right.exprType) {
                if let r = try convertExpression(right, to: left.exprType) {
                    right = r
                }
                else if let l = try convertExpression(left, to: right.exprType) {
                    left = l
                }
            }

            let range = CursorRange(left.range.start, right.range.end)
            guard left.exprType.equals(to: right.exprType) else {
                throw error(ParserMessage.binopArgTypeMatch(left.exprType, r: right.exprType), range)
            }
            guard isAccepting(op.value, argType: left.exprType) else {
                throw error(ParserMessage.binopArgTypeSupport(op.value, t: left.exprType), range)
            }
            
            let type = returnType(ofBinaryOperation: op.value, arg: left.exprType)
            left = BinaryOperator(name: op.value, exprType: type, arguments: (left, right), range: range)
        }
        
        if expectSemicolon, !consumeSep(";") { throw error(ParserMessage.expectedSemicolon) }
        return left
    }
    
    /// A single unit expression: `literal`, `value`, `procedure call`.
    func doExpr(in scope: Scope) throws -> Expression {
        let start = token.startCursor

        var arg: Expression!
        if consumePunct("(") {
            arg = try doExpression(in: scope, expectSemicolon: false)
            if !consumePunct(")") { throw error(ParserMessage.ifExpectedBrackets) }
            return arg
        }
        else if let (opTok, op) = consumeOperator() { // unary operation
            arg = try doExpr(in: scope)
            
            let type = try returnType(ofUnaryOperation: op.value, arg: arg.exprType)
            let op = UnaryOperator(name: op.value, exprType: type, argument: arg,
                                   range: CursorRange(opTok.range.start, arg.range.end))
            return op
        }
        
        let expression: Expression
        switch token.value {
            
        case let keyword as Keyword:
            guard nextToken() else { throw error(ParserMessage.unexpectedEndOfFile) }
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
                    throw error(ParserMessage.castExpectsTypeInBrackets, token.startCursor, token.endCursor)
                }
                let type = try doType(in: scope)
                guard consumePunct(")") else {
                    throw error(ParserMessage.castExpectsTypeInBrackets, token.startCursor, token.endCursor)
                }
                // @Todo: depend on this type to be resolved
                let expr = try doExpression(in: scope, expectSemicolon: false)
                expression = UnaryOperator(name: "cast", exprType: type.type, argument: expr,
                                           range: CursorRange(start, expr.range.end))
                
            default:
                print("Expression unknown: \(token)")
                throw error(ParserMessage.notImplemented(token), token.range)
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
                    var decl: VariableDeclaration! = stringLiterals[value]
                    if decl == nil {
                        let id = "\(scope.id)StringLiteral\(count)"
                        decl = VariableDeclaration(name: id, id: id, exprType: string,
                                                   flags: .isConstant, expression: StringLiteral(value: value),
                                                   ood: order())
                        stringLiterals[value] = decl
                    }
                    expression = Value(name: decl.name, id: decl.id, exprType: string)
                }
            }
            if !nextToken() { throw error(ParserMessage.unexpectedEndOfFile) }
        case let identifier as Identifier:
            let tok = token
            if matchProcCall() {
                expression = try doProcCall(in: scope)
                break
            }
            
            if !nextToken() { throw error(ParserMessage.unexpectedEndOfFile) }

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
                    else { throw error(ParserMessage.assignPassedNotValue(statement), tok.startCursor, tok.endCursor) }
                }
            }
        case is Punctuator: throw error(ParserMessage.expectedExpression)
        case is Separator: throw error(ParserMessage.expectedExpression)
        default:
            print("Expression unknown: \(token)")
            throw error(ParserMessage.notImplemented(token), token.range)
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
                throw error(ParserMessage.unexpectedToken(punct.value), token.startCursor, token.endCursor)
                
            case let keyword as Keyword: // @Clean: this is a copy from the main loop
                switch keyword {
                case .func:
                    throw error(ParserMessage.procNestedNotSupported, token.startCursor, token.endCursor)
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
                    guard nextToken() else { throw error(ParserMessage.unexpectedEndOfFile) }
                    let expr = try doExpression(in: scope, expectSemicolon: true)
                    let type = resolveType(of: expr)
                    guard type is PointerType else { throw error(ParserMessage.freeExpectsPointer) }
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
                    let returnRange = lastToken.range
                    var returnExpression: Expression?
                    if !consumeSep(";") {
                        returnExpression = try doExpression(in: scope, expectSemicolon: false)
                        // @Todo: should be expectSemicolon: true?
                        // are we even eating a semicolon?
                    }
                    let end = returnExpression?.range.end ?? returnRange.end
                    let returnStatement = Return(
                        value: returnExpression ?? VoidLiteral(),
                        range: CursorRange(returnRange.start, end))
                    statements.append(returnStatement)
                }
                else {
                    throw error(ParserMessage.unexpectedToken(keyword.rawValue), token.startCursor, token.endCursor)
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
                
                throw error(ParserMessage.unexpectedToken("\(token)"), token.startCursor, token.endCursor)
            case is Comment:
                if !nextToken() { break loop }
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop }}
                
            case is EOF:
                break loop
            default:
                throw error(ParserMessage.unexpectedToken("\(token)"), token.startCursor, token.endCursor)
            }
        }
        return statements
    }
    
    func parse() throws -> Code {
        loop: while tokens.count > i {
            
            switch token.value  {
            case let keyword as Keyword:
                if keyword == .func {
                    try doProcDecl()
                    break
                }
                if keyword == .struct {
                    try doStructDecl()
                    break
                }
                if keyword == .if { throw error(ParserMessage.ifNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if matchWhile() { throw error(ParserMessage.loopNotExpectedAtGlobalScope, token.startCursor, token.endCursor) }
                if keyword == .break { throw error(ParserMessage.breakContext, token.startCursor, token.endCursor) }
                if keyword == .continue { throw error(ParserMessage.continueContext, token.startCursor, token.endCursor) }
                if keyword == .fallthrough { throw error("@Todo: FALLTHROUGH ERROR MESSAGE", token.startCursor, token.endCursor) }

                print("Keyword \(keyword.rawValue) is not YET implemented.")
                throw error(ParserMessage.notImplemented(token), token.range)
                    
            case is Identifier:
                if matchWhile() { throw error(ParserMessage.loopNotExpectedAtGlobalScope) }
                
                if matchVarDecl() {
                    let decl = try doVarDecl(in: globalScope)
                    statements.append(decl)
                    break
                }
                
                print("(main loop) Unexpected identifier: feature might not have YET been implemented\n\(token)\n")
                throw error(ParserMessage.notImplemented(token), token.range)
            
            case let separator as Separator:
                if separator.value == ";" { if !nextToken() { break loop } /* ignore */ }
                
            default: if !nextToken() { break loop }
            }
        }

        // @Todo: tests will fail with this check
        // and it doesn't help much without #main working anyway
        //
        //  guard entry != nil else { throw error(ParserMessage.noEntryPoint) }

        let declarations: [Declaration] = Array(procedureDeclarations.values)
            + Array(structureDeclarations.values)
            + Array(stringLiterals.values)
        declarations.sorted(by: { $0.ood > $1.ood }).forEach { statements.insert($0, at: 0) }

        return Code(statements)
    }
}

// MARK: - Parser

final class Parser {
    
    init(fileName: String? = nil, _ tokens: [Token]) {
        self.fileName = fileName
        self.tokens = tokens
        self.token = tokens[i]
    }
    
    let fileName: String?
    let tokens: [Token]

    var statements: [Statement] = [] /// 
    var stringLiterals: [String: VariableDeclaration] = [:] /// inline string declarations
    var unresolved: [String: [Ast]] = [:] /// all with type unresolved
    var globalScope = Scope(id: Scope.globalId) /// all declarations in global scope

    var structureDeclarations: [String: StructDeclaration] = [:]
    var procedureDeclarations: [String: ProcedureDeclaration] = [:]
    var genericDeclarations: [String: (Declaration, [String])] = [:] /// structs or procedures and their generic types

    var scopeCounter = 0
    var i = 0
    var ood = 0 /// order of declaration
    var token: Token
    var entry: ProcedureDeclaration? /// main procedure of the program
}
