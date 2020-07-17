//
//  ControlFlow.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class Condition: Statement, Equatable, Copying {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Condition, rhs: Condition) -> Bool {
        lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block && lhs.elseBlock == rhs.elseBlock
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[If\(c)] \(condition)\n    Then: \(block)"
        if !elseBlock.isEmpty { string.append("\n    Else: \(elseBlock)") }
        return string
    }
    
    let condition: Expression
    let block: Code
    let elseBlock: Code
    
    internal init(condition: Expression, block: Code, elseBlock: Code,
                  range: CursorRange = CursorRange()) {
        self.condition = condition
        
        self.block = block
        self.elseBlock = elseBlock
        self.range = range
    }

    func makeCopy() -> Condition {
        Condition(condition: condition.makeCopy(), block: block.makeCopy(), elseBlock: elseBlock.makeCopy())
    }
}

final class WhileLoop: Statement, Equatable, Copying {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: WhileLoop, rhs: WhileLoop) -> Bool {
        lhs.userLabel == rhs.userLabel && lhs.condition.equals(to: rhs.condition) && lhs.block == rhs.block
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[While\(c)] "
        if let label = userLabel { string.append("(\(label)) ") }
        string.append("\(condition) \(block)")
        return string
    }
    
    let userLabel: String?
    let condition: Expression
    let block: Code

    internal init(userLabel: String?, condition: Expression, block: Code,
                  range: CursorRange = CursorRange()) {
        self.userLabel = userLabel
        self.condition = condition
        self.block = block
        self.range = range
    }

    func makeCopy() -> WhileLoop {
        WhileLoop(userLabel: userLabel, condition: condition.makeCopy(), block: block.makeCopy(), range: range)
    }
}

final class Break: Statement, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Break, rhs: Break) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Break\(c)] "
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?,
                  range: CursorRange = CursorRange()) {
        self.userLabel = userLabel
        self.range = range
    }

    func makeCopy() -> Break {
        Break(userLabel: userLabel, range: range)
    }
}

final class Continue: Statement, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Continue, rhs: Continue) -> Bool {
        lhs.userLabel == rhs.userLabel
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Continue\(c)]"
        if let label = userLabel { string.append("(\(label)) ") }
        return string
    }
    
    /// label set in the code
    let userLabel: String?
    
    internal init(userLabel: String?,
                  range: CursorRange = CursorRange()) {
        self.userLabel = userLabel
        self.range = range
    }

    func makeCopy() -> Continue {
        Continue(userLabel: userLabel, range: range)
    }
}

final class Return: Statement, Equatable, Copying {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Return, rhs: Return) -> Bool {
        lhs.value.equals(to: rhs.value)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Return\(c) \(value)]"
    }
    
    var value: Expression {
        didSet { range.end = value.range.end }
    }
    
    internal init(value: Expression,
                  range: CursorRange = CursorRange()) {
        self.value = value
        self.range = range
    }

    func makeCopy() -> Return {
        Return(value: value.makeCopy(), range: range)
    }
}
