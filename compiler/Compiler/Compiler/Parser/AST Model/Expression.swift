//
//  Expression.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class UnaryOperator: Expression, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    var operatorType: Type { argument.exprType }
    
    static func == (lhs: UnaryOperator, rhs: UnaryOperator) -> Bool {
        lhs.operatorType == rhs.operatorType
            && lhs.name == rhs.name
            && lhs.exprType == rhs.exprType
            && lhs.argument.equals(to: rhs.argument)
    }
    
    var debugDescription: String {
        "\(name){ \(argument) }"
    }
    
    var name: String
    var instruction: Instruction { return .add } // @Todo: make it work
    var argument: Expression
    var exprType: Type
    
    internal init(name: String, exprType: Type, argument: Expression) {
        self.name = name
        self.argument = argument
        self.exprType = exprType
    }
}

final class BinaryOperator: Expression, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    var operatorType: Type { arguments.0.exprType }
    
    static func == (lhs: BinaryOperator, rhs: BinaryOperator) -> Bool {
        lhs.name == rhs.name
            && lhs.operatorType == rhs.operatorType
            && lhs.exprType == rhs.exprType
            && lhs.arguments.0.equals(to: rhs.arguments.0)
            && lhs.arguments.1.equals(to: rhs.arguments.1)
    }
    
    var debugDescription: String {
        "[\(arguments.0) \(name) \(arguments.1)]"
    }
    
    var name: String
    var instruction: Instruction { return .add } // @Todo: I broke this
    var exprType: Type
    var arguments: (Expression, Expression)

    internal init(name: String, exprType: Type, arguments: (Expression, Expression)) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
    }
}

final class ProcedureCall: Expression, Statement, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType == rhs.exprType
            && lhs.arguments.elementsEqual(rhs.arguments) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        var string = "[Call] \(name)->\(exprType)"
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

final class StringLiteral: LiteralExpr, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "String(\"\(value)\")"
    }
    
    internal init(value: String) {
        self.value = value
    }

    var exprType: Type = .string
    var value: String
}

final class IntLiteral: LiteralExpr, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Int(\(value))"
    }
    
    internal init(value: Int) {
        self.value = value
        if value > Int32.max { exprType = .int64 }
    }

    var exprType: Type = .int
    var value: Int
}

final class FloatLiteral: LiteralExpr, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Float(\(value))"
    }
    
    internal init(value: Float32) {
        self.value = value
    }
    
    var exprType: Type = .float
    var value: Float32
}

final class BoolLiteral: LiteralExpr, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: BoolLiteral, rhs: BoolLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Bool(\(value))"
    }
    
    internal init(value: Bool) {
        self.value = value
    }
    
    var exprType: Type = .bool
    var value: Bool
}

final class VoidLiteral: LiteralExpr {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    var debugDescription: String { "[Void]" }
    
    var exprType: Type = .void
}
