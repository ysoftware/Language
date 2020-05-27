//
//  ControlFlow.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Condition: Statement {
    
    let condition: Expression
    let block: Scope
    let elseBlock: Scope
    
    internal init(condition: Expression, block: Scope, elseBlock: Scope) {
        self.condition = condition
        self.block = block
        self.elseBlock = elseBlock
    }
}

class WhileLoop: Statement {
    
    let userLabel: String?
    let condition: Expression
    let block: Scope

    internal init(userLabel: String?, condition: Expression, block: Scope) {
        self.userLabel = userLabel
        self.condition = condition
        self.block = block
    }
}

class Break: Statement {
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?) {
        self.userLabel = userLabel
    }
}

class Continue: Statement {
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?) {
        self.userLabel = userLabel
    }
}

class Return: Statement {
    
    let value: Expression
    
    internal init(value: Expression) {
        self.value = value
    }
}
