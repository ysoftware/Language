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
            && lhs.exprType == rhs.exprType
            && lhs.arguments.0.equals(to: rhs.arguments.0)
            && lhs.arguments.1.equals(to: rhs.arguments.1)
    }
    
    var debugDescription: String {
        "[Operation] \(arguments.0)\n\t\(name.rawValue)\n\t\(arguments.1)"
    }
    
    var name: Instruction
    var operatorType: Type
    var exprType: Type
    var arguments: (Expression, Expression)

    internal init(name: Instruction, operatorType: Type, exprType: Type, arguments: (Expression, Expression)) {
        self.name = name
        self.operatorType = operatorType
        self.exprType = exprType
        self.arguments = arguments
    }
}

class ProcedureCall: Expression, Statement, Equatable {
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType == rhs.exprType
            && lhs.arguments.elementsEqual(rhs.arguments) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        var string = "[Call] to \(name) -> \(exprType)"
        arguments.forEach { string.append("\n\t\($0)") }
        return string
    }
    
    var name: String
    var exprType: Type
    var arguments: [Expression]
    
    internal init(name: String, exprType: Type, arguments: [Expression]) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
    }
}

class StringLiteral: LiteralExpr, Equatable {
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[String Literal] \(value)"
    }
    
    internal init(value: String) {
        self.value = value
    }

    var exprType: Type = .string
    var value: String
}

class IntLiteral: LiteralExpr, Equatable {
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Int Literal] \(value)"
    }
    
    internal init(value: Int) {
        self.value = value
        if value > Int32.max { exprType = .int64 }
    }

    var exprType: Type = .int
    var value: Int
}

class FloatLiteral: LiteralExpr, Equatable {
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Float Literal] \(value)"
    }
    
    internal init(value: Float32) {
        self.value = value
    }
    
    var exprType: Type = .float
    var value: Float32
}

class BoolLiteral: LiteralExpr, Equatable {
    
    static func == (lhs: BoolLiteral, rhs: BoolLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "[Bool Literal] \(value)"
    }
    
    internal init(value: Bool) {
        self.value = value
    }
    
    var exprType: Type = .bool
    var value: Bool
}

class VoidLiteral: LiteralExpr {
    
    var debugDescription: String { "[Void] " }
    
    var exprType: Type = .void
}
