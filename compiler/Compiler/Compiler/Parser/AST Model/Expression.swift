//
//  Expression.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

/// A variable or constant passed by name.
final class Value: Expression, Equatable {
    
    var isRValue: Bool  { true }
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: Value, rhs: Value) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[Value\(c)] \(name): \(exprType)"
    }
    
    var name: String
    var exprType: Type
     
    // @Todo: not all values get cursors set up. maybe make these explicit without default value?
    internal init(name: String, exprType: Type, startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.name = name
        self.exprType = exprType
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class SizeOf: Expression, Equatable {
    
    var isRValue: Bool { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: SizeOf, rhs: SizeOf) -> Bool {
        lhs.type.equals(to: rhs.type)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[SizeOf\(c) \(type.typeName)]"
    }
    
    var exprType: Type
    var type: Type
    
    internal init( type: Type, exprType: Type = .int32, startCursor: Cursor, endCursor: Cursor) {
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.type = type
        self.exprType = exprType
    }
}

final class MemberAccess: Expression, Equatable {
    
    var isRValue: Bool { true }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: MemberAccess, rhs: MemberAccess) -> Bool {
        lhs.base.equals(to: rhs.base)
            && lhs.memberName == rhs.memberName
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.memberIndex == rhs.memberIndex
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        let i = memberIndex != nil ? "\(memberIndex!)" : "_"
        return "[Member \(i)\(c)] \(memberName): \(exprType.typeName) of \(base)"
    }
    
    var memberIndex: Int? = nil
    var memberName: String
    
    var base: Expression
    var exprType: Type
    
    internal init(base: Expression, memberName: String, memderIndex: Int?, exprType: Type,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.memberName = memberName
        self.exprType = exprType
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.base = base
        self.memberIndex = memderIndex
    }
}

final class UnaryOperator: Expression, Equatable {
    
    var isRValue: Bool  { true } // @Todo: not all operators produce an rValue
    
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
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        if name == UnaryOperator.cast {
            return "[Cast\(c) to \(exprType.typeName)] \(argument)"
        }
        return "\(name){ \(argument)\(c) }"
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
    
    var isRValue: Bool  { false }
    
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
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[Binop\(c) \(arguments.0) \(name) \(arguments.1)]"
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
    
    var isRValue: Bool  { false } // @Todo: sure about this?
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.arguments.elementsEqual(rhs.arguments) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        var string = "[Call\(c)] \(name)->\(exprType)"
        if !arguments.isEmpty {
            string += "\n("
            string += arguments.map { String(describing: $0) }.joined(separator: ", ")
            string += ")\n"
        }
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
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[String\(c) \"\(value.reescaped)\"]"
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
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[\(exprType.typeName)\(c) \(value)]"
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
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[Float\(c) \(value)]"
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

final class VoidLiteral: LiteralExpr {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[Void\(c)]"
    }
    
    var exprType: Type = .void
    
    internal init(startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

final class NullLiteral: LiteralExpr {
    
    var isRValue: Bool  { false }
    
    var startCursor: Cursor
    var endCursor: Cursor
    
    var debugDescription: String {
        let c = PrintCursors ? " \(startCursor)-\(endCursor)" : ""
        return "[null\(c)]"
    }
    
    var exprType: Type = .void
    
    internal init(exprType: Type,
                  startCursor: Cursor = Cursor(), endCursor: Cursor = Cursor()) {
        self.exprType = exprType
        self.startCursor = startCursor
        self.endCursor = endCursor
        
        guard !exprType.isResolved || exprType is PointerType else { report("Null literal is always a pointer.") }
    }
}
