//
//  ControlFlow.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Condition: Statement, Equatable {
    
    static func == (lhs: Condition, rhs: Condition) -> Bool {
        true // @Todo
    }
    
    
    var debugDescription: String {
        var string = "[If] \(condition)\n\tThen: \(block)"
        if !elseBlock.isEmpty { string.append("\n\tElse: \(elseBlock)") }
        return string
    }
    
    let condition: Expression
    let block: Scope
    let elseBlock: Scope
    
    internal init(condition: Expression, block: Scope, elseBlock: Scope) {
        self.condition = condition
        
        self.block = block
        self.elseBlock = elseBlock
    }
}

class WhileLoop: Statement, Equatable {

    static func == (lhs: WhileLoop, rhs: WhileLoop) -> Bool {
        true // @Todo
    }
    
    var debugDescription: String {
        var string = "[While] "
        if let label = userLabel { string.append("(\(label)) ") }
        string.append("\(condition) \(block)")
        return string
    }
    
    let userLabel: String?
    let condition: Expression
    let block: Scope

    internal init(userLabel:
    
    String?, condition: Expression, block: Scope) {
        self.userLabel = userLabel
        self.condition = condition
        self.block = block
    }
}

class Break: Statement, Equatable {
    
    static func == (lhs: Break, rhs: Break) -> Bool {
        true // @Todo
    }
    
    var debugDescription: String {
        var string = "[Break]"
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?) {
        self.userLabel = userLabel
    }
}

class Continue: Statement, Equatable {
    
    static func == (lhs: Continue, rhs: Continue) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        var string = "[Continue]"
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?) {
        self.userLabel = userLabel
    }
}

class Return: Statement, Equatable {
    
    static func == (lhs: Return, rhs: Return) -> Bool {
        lhs.value.equals(to: rhs.value)
    }
    
    var debugDescription: String {
        "Return \(value)"
    }
    
    let value: Expression
    
    internal init(value: Expression) {
        self.value = value
    }
}
