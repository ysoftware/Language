//
//  Expression.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class UnaryOperator: Expression, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    var operatorType: Type { argument.exprType }
    
    static func == (lhs: UnaryOperator, rhs: UnaryOperator) -> Bool {
        lhs.operatorType.equals(to: rhs.operatorType)
            && lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.argument.equals(to: rhs.argument)
    }
    
    var debugDescription: String {
        "\(name){ \(argument) }"
    }
    
    var name: String
    var argument: Expression
    var exprType: Type
    
    internal init(name: String, exprType: Type, argument: Expression,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.name = name
        self.argument = argument
        self.exprType = exprType
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class BinaryOperator: Expression, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    var operatorType: Type { arguments.0.exprType }
    
    static func == (lhs: BinaryOperator, rhs: BinaryOperator) -> Bool {
        lhs.name == rhs.name
            && lhs.operatorType.equals(to: rhs.operatorType)
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.arguments.0.equals(to: rhs.arguments.0)
            && lhs.arguments.1.equals(to: rhs.arguments.1)
    }
    
    var debugDescription: String {
        "[\(arguments.0) \(name) \(arguments.1)]"
    }
    
    var name: String
    var exprType: Type
    var arguments: (Expression, Expression)

    internal init(name: String, exprType: Type, arguments: (Expression, Expression),
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class ProcedureCall: Expression, Statement, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
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
    
    internal init(name: String, exprType: Type, arguments: [Expression],
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class StringLiteral: LiteralExpr, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "String(\"\(value)\")"
    }
    
    internal init(value: String,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.value = value
        self.startCursor = startCursor
        self.endCursor = endCursor
    }

    var exprType: Type = .string
    var value: String
}

final class IntLiteral: LiteralExpr, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Int(\(value))"
    }
    
    internal init(value: Int, exprType: Type = .int,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.value = value
        
        if value > Int32.max { self.exprType = .int64 }
        else { self.exprType = exprType }
        
        self.startCursor = startCursor
        self.endCursor = endCursor
    }

    var exprType: Type
    var value: Int
    var isFinalized = false
}

final class FloatLiteral: LiteralExpr, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Float(\(value))"
    }
    
    internal init(value: Float64, exprType: Type = .float,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.value = value
        self.exprType = exprType
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
    
    convenience init(intLiteral: IntLiteral) {
        self.init(value: Float64(intLiteral.value),
                  startCursor: intLiteral.startCursor, endCursor: intLiteral.endCursor)
    }
    
    var exprType: Type
    var value: Float64
    var isFinalized = false
}

final class BoolLiteral: LiteralExpr, Equatable {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: BoolLiteral, rhs: BoolLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        "Bool(\(value))"
    }
    
    internal init(value: Bool,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.value = value
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
    
    var exprType: Type = .bool
    var value: Bool
}

final class VoidLiteral: LiteralExpr {
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    var debugDescription: String { "[Void]" }
    
    var exprType: Type = .void
    
    internal init(startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}
