//
//  Procedure.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct ProcedureDeclaration: Declaration, Expression {
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        /// Last Argument is variadic
        static let isVarargs    = Flags(rawValue: 1 << 0)
        
        /// Is imported from another library
        static let isForeign    = Flags(rawValue: 1 << 1)
    }
    
    let id: String
    let name: String
    let arguments: [Type]
    let returnType: Type
    let flags: Flags
    let code: Scope
    
    let type: Type = .void
}

struct ProcedureCall: Expression {
    
    let name: String
    let type: Type
    let arguments: [Argument]
}
