//
//  BaseAST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Scope {
    
    let code: [Expression]
    
    static let empty = Scope(code: [])
    var isEmpty: Bool { code.isEmpty }
}

struct Argument: Expression {
    
    let name: String
    let type: Type
}

protocol Declaration {
    
}

protocol Expression {
    
    var type: Type { get }
}
