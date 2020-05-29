//
//  Statements.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 27.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class ProcedureDeclaration: Statement, Declaration {
    
    var debugDescription: String {
        var string = "[Procedure] \(name) -> \(returnType) " // @Todo print flags
        string.append("; args: ")
        string.append(arguments.map { "\($0)" }.joined(separator: ", "))
        if flags.contains(.isVarargs) { string.append("... ") }
        if flags.contains(.isForeign) { string.append("#foreign") }
        else if scope.isEmpty { string.append(" (empty body) ") }
        else { string.append("\n\(scope)\n") }
        return string
    }
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        /// Last Argument is variadic
        static let isVarargs    = Flags(rawValue: 1 << 0)
        
        /// Is imported from another library
        static let isForeign    = Flags(rawValue: 1 << 1)
    }
    
    var id: String
    var name: String
    var arguments: [Type]
    var returnType: Type
    var flags: Flags
    var scope: Scope
    
    internal init(id: String, name: String, arguments: [Type],
                  returnType: Type, flags: ProcedureDeclaration.Flags, scope: Scope) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.returnType = returnType
        self.flags = flags
        self.scope = scope
    }
}

class StructDeclaration: Statement, Declaration {
    
    var debugDescription: String {
        var string = "[Struct] \(name) "
        members.forEach { string.append("\n\t\t\($0) ") }
        return string
    }
    
    let name: String
    let members: [VariableDeclaration]
    
    internal init(name: String, members: [VariableDeclaration]) {
        self.name = name
        self.members = members
    }
}

class VariableDeclaration: Statement, Declaration {
    
    var debugDescription: String {
        var string = "[Variable] \(name): \(expType) "
        if flags.contains(.isConstant) { string.append("(constant) ") }
        if let exp = expression { string.append("= \(exp)") }
        return string
    }
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let isConstant  = Flags(rawValue: 1 << 0)
    }
    
    let name: String
    let expType: Type
    let flags: Flags
    let expression: Expression?
    
    internal init(name: String, expType: Type, flags: VariableDeclaration.Flags, expression: Expression?) {
        self.name = name
        self.expType = expType
        self.flags = flags
        self.expression = expression
    }
}

class VariableAssignment: Statement {
    
    var debugDescription: String {
        "[Assign] \(receiverId) = \(expression)"
    }
    
    let receiverId: String
    let expression: Expression
    
    internal init(receiverId: String, expression: Expression) {
        self.receiverId = receiverId
        self.expression = expression
    }
}
