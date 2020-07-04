//
//  Statements.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 27.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class Free: Statement, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Free, rhs: Free) -> Bool {
        lhs.expression.equals(to: rhs.expression)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Free\(c)]"
    }
    
    var expression: Expression
    
    internal init(expression: Expression, range: CursorRange = CursorRange()) {
        self.expression = expression
        self.range = range
    }
}

final class ProcedureDeclaration: Statement, Declaration, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: ProcedureDeclaration, rhs: ProcedureDeclaration) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.arguments == rhs.arguments
            && lhs.returnType.equals(to: rhs.returnType)
            && lhs.flags == rhs.flags
            && lhs.scope.equals(to: rhs.scope)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Procedure\(c) <\(id)>] \(name) -> \(returnType) "
        string.append("; args: ")
        string.append(arguments.map { "\($0)" }.joined(separator: ", "))
        if flags.contains(.isVarargs) { string.append("... ") }
        if flags.contains(.isForeign) { string.append("#foreign") }
        else if scope.isEmpty { string.append(" (empty body) ") }
        else { string.append("\n\(scope)\n") }
        return string
    }
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        /// Last Argument is variadic
        static let isVarargs    = Flags(rawValue: 1 << 0)
        
        /// Is imported from another library
        static let isForeign    = Flags(rawValue: 1 << 1)
        
        /// overwrites the main function
        static let main    = Flags(rawValue: 1 << 1)
    }
    
    var id: String
    var name: String
    var arguments: [Value]
    var returnType: Type
    var flags: Flags
    var scope: Code
    
    internal init(id: String, name: String, arguments: [Value],
                  returnType: Type, flags: ProcedureDeclaration.Flags, scope: Code,
                  range: CursorRange = CursorRange()) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.returnType = returnType
        self.flags = flags
        self.scope = scope
        self.range = range
    }
}

final class TypealiasDeclaration: Declaration, Equatable {

    var isRValue: Bool { false }
    var range: CursorRange

    static func == (lhs: TypealiasDeclaration, rhs: TypealiasDeclaration) -> Bool {
        return false
    }

    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[\(name) (\(id) as \(type.typeName) \(c)]"
    }

    var name: String
    var id: String
    var type: Type

    internal init(name: String, type: Type,
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.id = name
        self.type = type
        self.range = range
    }
}

final class StructDeclaration: Statement, Declaration, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: StructDeclaration, rhs: StructDeclaration) -> Bool {
        lhs.name == rhs.name
            && lhs.members.elementsEqual(rhs.members) { $0.equals(to: $1) }
            // @Todo: compare generic types
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Struct\(c) (\(id))] \(name) "
        if !genericTypes.isEmpty {
            string.append("generic: <\(genericTypes.joined(separator: ", "))> ")
        }
        members.forEach { string.append("\n        [Member] \($0.name): \($0.exprType.typeName)") }
        return string
    }
    
    let name: String
    let id: String
    let members: [VariableDeclaration]
    let genericTypes: [String]
    
    internal init(name: String, members: [VariableDeclaration], genericTypes: [String],
                  range: CursorRange = CursorRange()) {
        self.genericTypes = genericTypes
        self.name = name
        self.id = name // @Todo: do ids for generics
        self.members = members
        self.range = range
    }
}

final class VariableDeclaration: Statement, Declaration, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: VariableDeclaration, rhs: VariableDeclaration) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType.equals(to: rhs.exprType)
            && lhs.flags == rhs.flags
            && ((lhs.expression == nil && rhs.expression == nil) || (lhs.expression?.equals(to: rhs.expression) ?? false))
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[VarDecl\(c) <\(id)>] \(name): \(exprType) "
        if flags.contains(.isConstant) { string.append("(constant) ") }
        if let exp = expression { string.append("= \(exp) ") }
        else {
            if exprType is StructureType { string.append("[zero initialized] ") }
            else { string.append("[uninitialized] ") }
        }
        return string
    }
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let isConstant  = Flags(rawValue: 1 << 0)
    }
    
    let name: String
    let id: String
    let exprType: Type
    let flags: Flags
    let expression: Expression?
    
    internal init(name: String, id: String, exprType: Type, flags: VariableDeclaration.Flags, expression: Expression?,
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.id = id
        self.exprType = exprType
        self.flags = flags
        self.expression = expression
        self.range = range
    }
}

final class Assignment: Statement, Equatable {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        lhs.receiver.equals(to: rhs.receiver)
            && lhs.expression.equals(to: rhs.expression)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Assign\(c) \(receiver) = \(expression)]"
    }
    
    let receiver: Ast
    let expression: Expression
    
    internal init(receiver: Ast, expression: Expression,
                  range: CursorRange = CursorRange()) {
        guard receiver.isRValue else { report("Initializing an assignment statement with a non-rvalue receiver.") }
        self.receiver = receiver
        self.expression = expression
        self.range = range
    }
}
