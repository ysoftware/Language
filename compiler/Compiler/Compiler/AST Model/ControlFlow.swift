//
//  ControlFlow.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Condition: Expression {
    
    let condition: Expression
    let block: Scope
    let elseBlock: Scope
    
    // @Todo: I should refactor this and return
    // into Statement? so they don't have a type
    var type: Type = .void
}
