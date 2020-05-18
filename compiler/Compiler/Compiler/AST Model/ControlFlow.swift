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

struct ConditionalLoop: Statement {

    let condition: Expression
    let block: Scope
}
