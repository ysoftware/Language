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
    
    func consumeNext<T: StringValueToken>(_ type: T.Type, matching value: String) -> Bool {
        return consumeNext(where: { ($0 as? T)?.value == value }) != nil
    }
    
    // consume identifier is not needed
    // consume keyword is not needed
    // consume directive is not needed
    // consume operator is not needed
    
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
    
    
    // Cycle
    
    while tokens.count > i {
        switch token.value  {
            
        case let keyword as Keyword:
            // PROCEDURE DECLARATION
            
            if keyword == .func {
                let id: String
                let name: String
                var arguments: [Type] = []
                let returnType: Type
                var flags = ProcedureDeclaration.Flags()
                let scope: Scope = .empty // @Todo: for now
                
                if let (_, nameIdentifier) = consumeNext(Identifier.self) {
                    name = nameIdentifier.value
                    id = "global_func_\(nameIdentifier.value)"
                    
                    guard consumeNext(Punctuator.self, matching: "(")
                        else { return error(.procExpectedBrace) }
                    
                    while tokens.count > i { // parse arguments
                        
                        if consumeNext(Punctuator.self, matching: "...") {
                            flags.insert(.isVarargs)
                            break
                        }
                        else {
                            guard let _ = peekNext()?.value as? Identifier else { break }
                            guard let argumentName = consumeNext(Identifier.self),
                                consumeNext(Punctuator.self, matching: ":"),
                                let (_, argumentType) = consumeNext(Identifier.self)
                                else { return error(.procExpectedArgumentType) }
                            
                            // @Todo: change argument from Type to something
                            // that will also contain argument name and label
                            arguments.append(Type(name: argumentType.value))
                        }
                        
                        if !consumeNext(Separator.self, matching: ",") {
                            break
                        }
                    }
                    
                    guard consumeNext(Punctuator.self, matching: ")")
                        else { return error(.procExpectedBrace) }
                    
                    if consumeNext(Punctuator.self, matching: "->") {
                        if let (_, type) = consumeNext(Identifier.self) {
                            returnType = Type(name: type.value)
                        }
                        else {
                            return error(.procReturnTypeExpected)
                        }
                    }
                    else {
                        returnType = .void
                    }
                    
                    if let (_, directive) = consumeNext(Directive.self) {
                        if directive.value == "foreign" {
                            flags.insert(.isForeign)
                        }
                        else {
                            return error(.procUndeclaredDirective)
                        }
                    }
                    
                    statements.append(ProcedureDeclaration(
                        id: id, name: name, arguments: arguments,
                        returnType: returnType, flags: flags,scope: scope))
                }
                else {
                    return error(.procExpectedName)
                }
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
