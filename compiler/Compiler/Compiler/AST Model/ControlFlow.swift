//
//  ControlFlow.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Condition: Statement {
    
    let condition: Expression
    let block: Scope
    let elseBlock: Scope
}

struct WhileLoop: Statement {

    let userLabel: String?
    let condition: Expression
    let block: Scope
}

struct Break: Statement {
    
    /// label set in the code
    let userLabel: String?
}

struct Continue: Statement {
    
    /// label set in the code
    let userLabel: String?
}
