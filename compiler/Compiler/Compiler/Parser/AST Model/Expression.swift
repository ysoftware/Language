//
//  Expression.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class New: Expression, Equatable {

    var isRValue: Bool  { false }
    var range: CursorRange

    static func == (lhs: New, rhs: New) -> Bool {
        lhs.type.equals(to: rhs.type)
    }

    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[New\(c)]"
    }

    var type: Type
    var exprType: Type

    internal init(type: Type, range: CursorRange = CursorRange()) {
        self.range = range
        self.type = type
        self.exprType = pointer(type)
    }

    func makeCopy() -> New {
        New(type: type, range: range)
    }
}

/// A variable or constant passed by name.
final class Value: Expression, Equatable, Copying {
    
    var isRValue: Bool  { true }
    var range: CursorRange
    
    static func == (lhs: Value, rhs: Value) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Value\(c) <\(id)>] \(name): \(exprType)"
    }
    
    var name: String
    var id: String = ""
    var exprType: Type
     
    // @Todo: not all values get cursors set up. maybe make these explicit without default value?
    internal init(name: String, id: String, exprType: Type, range: CursorRange = CursorRange()) {
        self.name = name
        self.id = id
        self.exprType = exprType
        self.range = range
    }

    func makeCopy() -> Value {
        Value(name: name, id: id, exprType: exprType, range: range)
    }
}

final class SizeOf: Expression, Equatable {
    
    var isRValue: Bool { false }
    var range: CursorRange
    
    static func == (lhs: SizeOf, rhs: SizeOf) -> Bool {
        lhs.type.equals(to: rhs.type)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[SizeOf\(c) \(type.typeName)]"
    }
    
    var exprType: Type
    var type: Type
    
    internal init( type: Type, exprType: Type = int32, range: CursorRange) {
        self.range = range
        self.type = type
        self.exprType = exprType
    }

    func makeCopy() -> SizeOf {
        SizeOf(type: type, exprType: exprType, range: range)
    }
}

final class Subscript: Expression, Equatable {

    var isRValue: Bool { true }
    var range: CursorRange

    static func == (lhs: Subscript, rhs: Subscript) -> Bool {
        lhs.base.equals(to: rhs.base)
            && lhs.index.equals(to: rhs.index)
            && lhs.exprType.equals(to: rhs.exprType)
    }

    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "\(base) subscript \(index)\(c)"
    }

    var index: Expression
    var base: Expression
    var exprType: Type

    internal init(base: Expression, exprType: Type, index: Expression, range: CursorRange) {
        self.range = range
        self.index = index
        self.base = base
        self.exprType = exprType
    }

    func makeCopy() -> Subscript {
        Subscript(base: base, exprType: exprType, index: index, range: range)
    }
}

final class MemberAccess: Expression, Equatable {
    
    var isRValue: Bool { true }
    var range: CursorRange
    
    static func == (lhs: MemberAccess, rhs: MemberAccess) -> Bool {
        lhs.base.equals(to: rhs.base)
            && lhs.memberName == rhs.memberName
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.memberIndex == rhs.memberIndex
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        let i = memberIndex != nil ? "\(memberIndex!)" : "_"
        return "[Member \(i)\(c)] \(memberName): \(exprType.typeName) of \(base)"
    }
    
    var memberIndex: Int? = nil
    var memberName: String
    
    var base: Expression
    var exprType: Type
    
    internal init(base: Expression, memberName: String, memderIndex: Int?, exprType: Type,
                  range: CursorRange = CursorRange()) {
        self.memberName = memberName
        self.exprType = exprType
        self.range = range
        self.base = base
        self.memberIndex = memderIndex
    }

    func makeCopy() -> MemberAccess {
        MemberAccess(base: base.makeCopy(), memberName: memberName, memderIndex: memberIndex,
                     exprType: exprType, range: range)
    }
}

final class UnaryOperator: Expression, Equatable {
    
    var isRValue: Bool  { true } // @Todo: not all operators produce an rValue
    var range: CursorRange

    var operatorType: Type { argument.exprType }
    
    static func == (lhs: UnaryOperator, rhs: UnaryOperator) -> Bool {
        lhs.operatorType.equals(to: rhs.operatorType)
            && lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.argument.equals(to: rhs.argument)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        if name == UnaryOperator.cast {
            return "[Cast\(c) to \(exprType.typeName)] \(argument)"
        }
        return "[\(name) \(exprType.typeName): \(argument)\(c)]"
    }
    
    var name: String
    var argument: Expression
    var exprType: Type
    
    internal init(name: String, exprType: Type, argument: Expression,
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.argument = argument
        self.exprType = exprType
        self.range = range
    }

    func makeCopy() -> UnaryOperator {
        UnaryOperator(name: name, exprType: exprType, argument: argument.makeCopy(), range: range)
    }
}

final class BinaryOperator: Expression, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    var operatorType: Type { arguments.0.exprType }
    
    static func == (lhs: BinaryOperator, rhs: BinaryOperator) -> Bool {
        lhs.name == rhs.name
            && lhs.operatorType.equals(to: rhs.operatorType)
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.arguments.0.equals(to: rhs.arguments.0)
            && lhs.arguments.1.equals(to: rhs.arguments.1)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Binop\(c) \(arguments.0) \(name) \(arguments.1)]"
    }
    
    var name: String
    var exprType: Type
    var arguments: (Expression, Expression)

    internal init(name: String, exprType: Type, arguments: (Expression, Expression),
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
        self.range = range
    }

    func makeCopy() -> BinaryOperator {
        BinaryOperator(name: name, exprType: exprType,
                       arguments: (arguments.0.makeCopy(), arguments.1.makeCopy()), range: range)
    }
}

final class ProcedureCall: Expression, Statement, Equatable {
    
    var isRValue: Bool  { false } // @Todo: sure about this?
    var range: CursorRange
    
    static func == (lhs: ProcedureCall, rhs: ProcedureCall) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.arguments.elementsEqual(rhs.arguments) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Call\(c)] \(name) -> \(exprType)"
        if !arguments.isEmpty {
            string += "\n\t\t\t("
            string += arguments.map { String(describing: $0) }.joined(separator: ", ")
            string += ")"
        }
        return string
    }

    var id: String {
        if solidTypes.isEmpty {
            return name
        } else {
            return solidId(for: name, solidTypes: solidTypes)
        }
    }

    let name: String
    var exprType: Type
    var arguments: [Expression]
    var solidTypes: [Type]
    
    internal init(name: String, exprType: Type, arguments: [Expression], solidTypes: [Type] = [],
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.exprType = exprType
        self.arguments = arguments
        self.range = range
        self.solidTypes = solidTypes
    }

    func makeCopy() -> ProcedureCall {
        let args = arguments.map { ($0 as Copying).makeCopy() } as! [Expression]
        return ProcedureCall(name: name, exprType: exprType, arguments: args,
                             solidTypes: solidTypes, range: range)
    }
}

final class StringLiteral: LiteralExpr, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[String\(c) \"\(value.reescaped)\"]"
    }
    
    internal init(value: String,
                  range: CursorRange = CursorRange()) {
        self.value = value
        self.range = range
    }

    var exprType: Type = string
    var value: String

    func makeCopy() -> StringLiteral {
        StringLiteral(value: value, range: range)
    }
}

final class IntLiteral: LiteralExpr, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: IntLiteral, rhs: IntLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[\(exprType.typeName)\(c) \(value)]"
    }
    
    internal init(value: Int, exprType: Type = int,
                  range: CursorRange = CursorRange()) {
        self.value = value
        
        if value > Int32.max { self.exprType = int64 }
        else { self.exprType = exprType }
        
        self.range = range
    }

    var exprType: Type
    var value: Int
    var isFinalized = false

    func makeCopy() -> IntLiteral {
        IntLiteral(value: value, exprType: exprType, range: range)
    }
}

final class FloatLiteral: LiteralExpr, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: FloatLiteral, rhs: FloatLiteral) -> Bool {
        lhs.value == rhs.value
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Float\(c) \(value)]"
    }
    
    internal init(value: Float64, exprType: Type = float,
                  range: CursorRange = CursorRange()) {
        self.value = value
        self.exprType = exprType
        self.range = range
    }
    
    convenience init(intLiteral: IntLiteral) {
        self.init(value: Float64(intLiteral.value), range: intLiteral.range)
    }
    
    var exprType: Type
    var value: Float64
    var isFinalized = false

    func makeCopy() -> FloatLiteral {
        FloatLiteral(value: value, exprType: exprType, range: range)
    }
}

final class VoidLiteral: LiteralExpr {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Void\(c)]"
    }
    
    var exprType: Type = void
    
    internal init(range: CursorRange = CursorRange()) {
        self.range = range
    }

    func makeCopy() -> VoidLiteral {
        VoidLiteral(range: range)
    }
}

final class NullLiteral: LiteralExpr {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[null\(c)]"
    }
    
    var exprType: Type = void
    
    internal init(exprType: Type,
                  range: CursorRange = CursorRange()) {
        self.exprType = exprType
        self.range = range
        
        guard !exprType.isResolved || exprType is PointerType else { report("Null literal is always a pointer.") }
    }

    func makeCopy() -> NullLiteral {
        NullLiteral(exprType: exprType, range: range)
    }
}
