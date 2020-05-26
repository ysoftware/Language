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
    
    var i = 0
    var token = tokens[i]
    var statements: [Statement] = []
    
    // Methods
    
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
    func consumeIdent() -> (Token, Identifier)? { consumeNext(Identifier.self) }
    
    func parseProcedure() -> Result<ProcedureDeclaration, ParserError> {
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
                arguments.append(Type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        
        if !consumePunct(")") { return error(.procExpectedBrackets) }
        
        if consumePunct("->") {
            if let (_, type) = consumeNext(Identifier.self) { returnType = Type(name: type.value) }
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
            if let error = parseStatements().then({ scope = Scope(code: $0) }) { return .failure(error) }
        }
        return .success(ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope))
    }
    
    func parseIf() -> Result<Condition, ParserError> {
        let hasParenthesis = consumePunct("(")
        var condition: Expression!
        var ifBody: [Statement] = []
        var elseBody: [Statement] = []
        
        if hasParenthesis {
            if let error = parseExpression().then({ condition = $0 }) { return .failure(error) }
            if !consumePunct(")") { return error(.ifExpectedClosingParenthesis) }
        }
        
        if !consumePunct("{") { return error(.ifExpectedBrackets) }
        if let error = parseStatements().then({ ifBody = $0 }) { return .failure(error) }
        
        // else
        if consumeKeyword(.else) {
            if !consumePunct("{") { return error(.ifExpectedBrackets) }
            if let error = parseStatements().then({ elseBody = $0 }) { return .failure(error) }
        }
        
        return .success(Condition(condition: condition,
                                  block: Scope(code: ifBody), elseBlock: Scope(code: elseBody)))
    }
    
    func parseExpression() -> Result<Expression, ParserError> {
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
                
                // @Todo: this is the first time we need some form of type checking
                // we have to make sure this value is of type bool
                return .success(Argument(name: identifier.value, expType: .bool))
                
            default:
                break
            }
            nextToken()
        }
        return error(.notImplemented)
    }
    
    // body of: procedure, if-else, loop
    func parseStatements() -> Result<[Statement], ParserError> {
        var statements: [Statement] = []
        
        while tokens.count > i {
            switch token.value  {
            
            case let punct as Punctuator:
                if punct.value == "}" { // done with the scope
                    nextToken()
                    return .success(statements)
                }
                
            case let keyword as Keyword:
                if keyword == .func { return error(.procNestedNotSupported) }
                if keyword == .if {
                    if let error = parseIf().then({ statements.append($0) }) { return .failure(error) }
                }
                
            default:
                break
            }
            nextToken()
        }
        return .success(statements)
    }
    
    // Cycle
    
    while tokens.count > i {
        switch token.value  {
        
        case let keyword as Keyword:
            // PROCEDURE DECLARATION
            if keyword == .func {
                if let error = parseProcedure().then({ statements.append($0) }) { return .failure(error) }
                
            }
            
        default:
            break
        }
        nextToken()
    }
    return .success(Scope(code: statements))
}

func parseExpression(_ expression: Expression) {
    
}

func parseStatement(_ statement: Statement) {
    
    
    // FUNCTION
    
}
