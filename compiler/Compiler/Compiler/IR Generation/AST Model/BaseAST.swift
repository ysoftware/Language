//
//  BaseAST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Scope {
    
    var code: [Statement]
    
    static let empty = Scope(code: [])
    var isEmpty: Bool { code.isEmpty }
    
    internal init(code: [Statement]) {
        self.code = code
    }
}

protocol Ast: class { }

protocol Literal { }

protocol Statement: Ast { }

protocol Expression: Ast {
    
    var expType: Type { get }
}
