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
    
    func consumeNext<T: TokenValue>(_ value: T.Type) -> T? {
        let nextIndex = i + 1
        guard tokens.count > nextIndex else { return nil }
        let token = tokens[nextIndex]
        if let expectedToken = token as? T {
            advance()
            return expectedToken
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
                let flags: ProcedureDeclaration.Flags
                let scope: Scope = .empty // @Todo: for now
                
//                if let token = consumeNext(Identifier.self) {
//                    name = token.value
//                    
//                    guard consumeNext(Punctuator.self)?.value == "("
//                        else { return error(.procExpectedBrace) }
//                    
//                    while tokens.count > i { // parse arguments
//                        guard let _ = peekNext()?.value as? Identifier else { break }
//                        guard let argumentName = consumeNext(Identifier.self),
//                            consumeNext(Punctuator.self)?.value == ":",
//                            let argumentType = consumeNext(Identifier.self)
//                                else { return error(.procExpectedArgumentType) }
//                        
//                        // @Todo: consume function that checks both
//                        // type and value
//                        
//                        // @Todo: change argument from Type to something
//                        // that will also contain argument name and label
//                        arguments.append(Type(name: argumentType.value))
//                    }
//                    
//                    guard consumeNext(Punctuator.self)?.value == ")"
//                        else { return error(.procExpectedBrace) }
//                    
//                    statements.append(ProcedureDeclaration(
//                        id: id, name: name, arguments: arguments,
//                        returnType: returnType, flags: flags,scope: scope))
//                }
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
