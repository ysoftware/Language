//
//  Expression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class BinaryOperator: Expression, Equatable {
    
    static func == (lhs: BinaryOperator, rhs: BinaryOperator) -> Bool {
        lhs.name == rhs.name
            && lhs.operatorType == rhs.operatorType
            && lhs.expType == rhs.expType
            && lhs.arguments.0.equals(to: rhs.arguments.0)
            && lhs.arguments.1.equals(to: rhs.arguments.1)
    }
    
    var debugDescription: String {
        "[Operation] \(arguments.0)\n\t\(name.rawValue)\n\t\(arguments.1)"
    }
    
    let name: Instruction
    let operatorType: Type
    let expType: Type
    let arguments: (Expression, Expression)

    internal init(name: Instruction, operatorType: Type, expType: Type, arguments: (Expression, Expression)) {
        self.name = name
        self.operatorType = operatorType
        self.expType = expType
        self.arguments = arguments
    }
}

class ProcedureCall: Expression, Statement, Equatable {
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.expType == rhs.expType
            && lhs.arguments.elementsEqual(rhs.arguments) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        var string = "[Call] to \(name) -> \(expType)"
        arguments.forEach { string.append("\n\t\($0)") }
        return string
    }
    
    var name: String
    var expType: Type
    var arguments: [Expression]
    
    internal init(name: String, expType: Type, arguments: [Expression]) {
        self.name = name
        self.expType = expType
        self.arguments = arguments
    }
}

class StringLiteral: Expression, Literal, Equatable {
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[String Literal] \(value)"
    }
    
    internal init(value: String) {
        self.value = value
    }

    let expType: Type = .string
    let value: String
}

class IntLiteral: Expression, Literal, Equatable {
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Int Literal] \(value)"
    }
    
    internal init(value: Int) {
        self.value = value
    }

    // @Todo: make it choose the type appropriately depending on value
    let expType: Type = .int
    let value: Int
}

class FloatLiteral: Expression, Equatable {
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Float Literal] \(value)"
    }
    
    internal init(value: Float32) {
        self.value = value
    }
    
    let expType: Type = .float
    let value: Float32
}

class BoolLiteral: Expression, Literal, Equatable {
    
    static func == (lhs: BoolLiteral, rhs: BoolLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Float Literal] \(value)"
    }
    
    internal init(value: Bool) {
        self.value = value
    }
    
    let expType: Type = .bool
    let value: Bool
}
