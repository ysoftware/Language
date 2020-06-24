//
//  ControlFlow.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class Condition: Statement, Equatable {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: Condition, rhs: Condition) -> Bool {
        lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block && lhs.elseBlock == rhs.elseBlock
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        var string = "[If\(c)] \(condition)\n    Then: \(block)"
        if !elseBlock.isEmpty { string.append("\n    Else: \(elseBlock)") }
        return string
    }
    
    let condition: Expression
    let block: Code
    let elseBlock: Code
    
    internal init(condition: Expression, block: Code, elseBlock: Code,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.condition = condition
        
        self.block = block
        self.elseBlock = elseBlock
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class WhileLoop: Statement, Equatable {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: WhileLoop, rhs: WhileLoop) -> Bool {
        lhs.userLabel == rhs.userLabel && lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        var string = "[While\(c)] "
        if let label = userLabel { string.append("(\(label)) ") }
        string.append("\(condition) \(block)")
        return string
    }
    
    let userLabel: String?
    let condition: Expression
    let block: Code

    internal init(userLabel:
    
    String?, condition: Expression, block: Code,
             startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.userLabel = userLabel
        self.condition = condition
        self.block = block
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class Break: Statement, Equatable {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: Break, rhs: Break) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        var string = "[Break\(c)] "
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.userLabel = userLabel
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class Continue: Statement, Equatable {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: Continue, rhs: Continue) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        var string = "[Continue\(c)]"
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.userLabel = userLabel
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class Return: Statement, Equatable {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: Return, rhs: Return) -> Bool {
        lhs.value.equals(to: rhs.value)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[Return\(c) \(value)]"
    }
    
    var value: Expression {
        didSet { endCursor = value.endCursor }
    }
    
    internal init(value: Expression,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.value = value
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}
