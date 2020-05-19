//
//  BaseAST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Scope {
    
    let code: [Statement]
    
    static let empty = Scope(code: [])
    var isEmpty: Bool { code.isEmpty }
}

struct Argument: Expression {
    
    let name: String
    let expType: Type
}

protocol Statement { }

protocol Expression {
    
    var expType: Type { get }
}
