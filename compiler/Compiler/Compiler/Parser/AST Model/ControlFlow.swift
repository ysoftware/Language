//
//  ControlFlow.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class Condition: Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: Condition, rhs: Condition) -> Bool {
        lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block && lhs.elseBlock == rhs.elseBlock
    }
    
    var debugDescription: String {
        var string = "[If] \(condition)\n\tThen: \(block)"
        if !elseBlock.isEmpty { string.append("\n\tElse: \(elseBlock)") }
        return string
    }
    
    let condition: Expression
    let block: Code
    let elseBlock: Code
    
    internal init(condition: Expression, block: Code, elseBlock: Code) {
        self.condition = condition
        
        self.block = block
        self.elseBlock = elseBlock
    }
}

final class WhileLoop: Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: WhileLoop, rhs: WhileLoop) -> Bool {
        lhs.userLabel == rhs.userLabel && lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block
    }
    
    var debugDescription: String {
        var string = "[While] "
        if let label = userLabel { string.append("(\(label)) ") }
        string.append("\(condition) \(block)")
        return string
    }
    
    let userLabel: String?
    let condition: Expression
    let block: Code

    internal init(userLabel:
    
    String?, condition: Expression, block: Code) {
        self.userLabel = userLabel
        self.condition = condition
        self.block = block
    }
}

final class Break: Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: Break, rhs: Break) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        var string = "[Break] "
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?) {
        self.userLabel = userLabel
    }
}

final class Continue: Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
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

final class Return: Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
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
