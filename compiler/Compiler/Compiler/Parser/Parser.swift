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
    func error(_ error: ParserError.Message) -> Result<Scope, ParserError> {
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
        let token = tokens[nextIndex]
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
        let token = tokens[nextIndex]
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
    
    func consumePunct(_ value: String) -> Bool { consumeNext(Punctuator.self, matching: value) }
    func consumeSep(_ value: String) -> Bool { consumeNext(Separator.self, matching: value) }
    func consumeIdent() -> (Token, Identifier)? { consumeNext(Identifier.self) }
    
    func parseProcedure() -> ParserError.Message? {
        var arguments: [Type] = []
        let returnType: Type
        var flags = ProcedureDeclaration.Flags()
        let scope: Scope = .empty // @Todo: for now
        
        guard let (_, procName) = consumeIdent() else { return .procExpectedName }
        let name = procName.value
        let id = "global_func_\(procName.value)"
        
        guard consumePunct("(") else { return .procExpectedBrace }
        
        // arguments
        while tokens.count > i {
            if consumePunct("...") {
                if arguments.isEmpty { return .procExpectedArgumentBeforeVarargs }
                flags.insert(.isVarargs)
                break
            }
            else {
                guard peekNext()?.value is Identifier else { return .procExpectedArgumentName }
                
                guard let (_, argName) = consumeIdent(), consumePunct(":"),
                    let (_, argType) = consumeIdent()
                    else { return .procExpectedArgumentType }
                
                // @Todo: change argument from Type to something
                // that will also contain argument name and label
                _ = argName
                arguments.append(Type(name: argType.value))
            }
            if !consumeSep(",") { break }
        }
        
        if !consumePunct(")") { return .procExpectedBrace }
        
        if consumePunct("->") {
            if let (_, type) = consumeNext(Identifier.self) {
                returnType = Type(name: type.value)
            }
            else { return .procReturnTypeExpected }
        }
        else { returnType = .void }
        
        // directives
        if let (_, directive) = consumeNext(Directive.self) {
            if directive.value == "foreign" {
                flags.insert(.isForeign)
            }
            else {
                return .procUndeclaredDirective
            }
        }
        
        // procedure body
        if consumePunct("{") {
            if flags.contains(.isForeign) { return .procForeignUnexpectedBody }
            
            // parse scope until matching "}"
            
        }
        
        statements.append(ProcedureDeclaration(
            id: id, name: name, arguments: arguments,
            returnType: returnType, flags: flags, scope: scope))
        return nil
    }
    
    
    
    
    
    // Cycle
    
    while tokens.count > i {
        switch token.value  {
            
        case let keyword as Keyword:
            // PROCEDURE DECLARATION
            if keyword == .func, let message = parseProcedure() { return error(message) }
            
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
