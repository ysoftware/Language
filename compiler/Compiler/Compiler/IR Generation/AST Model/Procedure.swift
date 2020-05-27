//
//  Procedure.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class ProcedureDeclaration: Statement {
    
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

class Value: Expression {
    
    var name: String
    var expType: Type
    
    internal init(name: String, expType: Type) {
        self.name = name
        self.expType = expType
    }
}

class ProcedureCall: Expression, Statement {
    
    var name: String
    var expType: Type
    var arguments: [Expression]
    
    internal init(name: String, expType: Type, arguments: [Expression]) {
        self.name = name
        self.expType = expType
        self.arguments = arguments
    }
}
