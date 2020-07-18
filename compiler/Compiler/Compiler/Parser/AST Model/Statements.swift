//
//  Statements.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 27.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class Free: Statement, Equatable, Copying {
    
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

    func makeCopy() -> Free {
        Free(expression: expression.makeCopy(), range: range)
    }
}

final class ProcedureDeclaration: Statement, Declaration, Equatable {

    var ood: Int // @Todo: remove this when 2nd pass is implemented

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
        var string = "\n[Procedure\(c) <\(id)>] \(name) -> \(returnType) "
        if !arguments.isEmpty {
            string.append("\n    ; args: \n")
            string.append(arguments.map { "         \($0)" }.joined(separator: "\n"))
            if flags.contains(.isVarargs) { string.append("... ") }
        }
        if flags.contains(.main) { string.append(" #main") }
        if flags.contains(.isForeign) { string.append(" #foreign") }
        else if scope.isEmpty { string.append(" (empty body) ") }
        else { string.append("\n\(scope)\n") }
        return string
    }
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        /// Last Argument is variadic
        static let isVarargs = Flags(rawValue: 1 << 1)
        /// Is imported from another library
        static let isForeign = Flags(rawValue: 1 << 2)
        /// overwrites the main function
        static let main      = Flags(rawValue: 1 << 3)
    }
    
    let id: String
    let name: String
    let arguments: [Value]
    let returnType: Type
    let flags: Flags
    let scope: Code

    internal init(id: String, name: String, arguments: [Value],
                  returnType: Type, flags: ProcedureDeclaration.Flags, scope: Code,
                  range: CursorRange = CursorRange(), ood: Int = 0) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.returnType = returnType
        self.flags = flags
        self.scope = scope
        self.range = range
        self.ood = ood
    }

    func makeCopy() -> ProcedureDeclaration {
        ProcedureDeclaration(id: id, name: name, arguments: arguments.makeCopy(),
                             returnType: returnType, flags: flags, scope: scope.makeCopy(),
                             range: range, ood: ood)
    }
}

final class TypealiasDeclaration: Declaration, Equatable, Copying {

    var ood: Int  = 0 // @Todo: remove this, ignored

    var isRValue: Bool { false }
    var range: CursorRange

    static func == (lhs: TypealiasDeclaration, rhs: TypealiasDeclaration) -> Bool {
        return false
    }

    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Alias '\(name)'\(c)]"
    }

    var name: String
    var id: String
    // @Todo: add type here if you decide to have an actual user-level typealias declaration

    internal init(name: String,
                  range: CursorRange = CursorRange()) {
        self.name = name
        self.id = name
        self.range = range
    }

    func makeCopy() -> TypealiasDeclaration {
        TypealiasDeclaration(name: name, range: range)
    }
}

final class StructDeclaration: Statement, Declaration, Equatable {

    var ood: Int // @Todo: remove this when 2nd pass is implemented
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: StructDeclaration, rhs: StructDeclaration) -> Bool {
        lhs.name == rhs.name
            && lhs.members.elementsEqual(rhs.members) { $0.equals(to: $1) }
            && lhs.id == rhs.id
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        var string = "[Struct\(c) \(id)]\n"
        string.append(members.map { "        [Member] \($0.name): \($0.exprType.typeName)" }.joined(separator: ",\n"))
        return string
    }
    
    let name: String
    let id: String
    var members: [VariableDeclaration]

    internal init(name: String, id: String, members: [VariableDeclaration], range: CursorRange = CursorRange(), ood: Int = 0) {
        self.name = name
        self.id = id
        self.members = members
        self.range = range
        self.ood = ood
    }

    func makeCopy() -> StructDeclaration {
        StructDeclaration(name: name, id: id, members: members.makeCopy(), range: range, ood: ood)
    }
}

final class VariableDeclaration: Statement, Declaration, Equatable, Copying {

    var ood: Int // @Todo: remove this when 2nd pass is implemented

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
        if let exp = expression { string.append("\n        = \(exp) ") }
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
    var exprType: Type
    let flags: Flags
    let expression: Expression?
    
    internal init(name: String, id: String, exprType: Type, flags: VariableDeclaration.Flags, expression: Expression?,
                  range: CursorRange = CursorRange(), ood: Int = 0) {
        self.name = name
        self.id = id
        self.exprType = exprType
        self.flags = flags
        self.expression = expression
        self.range = range
        self.ood = ood
    }

    func makeCopy() -> VariableDeclaration {
        VariableDeclaration(name: name, id: id, exprType: exprType, flags: flags,
                            expression: expression?.makeCopy(), range: range, ood: ood)
    }
}

final class Assignment: Statement, Equatable, Copying {
    
    var isRValue: Bool  { false }
    var range: CursorRange
    
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        lhs.receiver.equals(to: rhs.receiver)
            && lhs.expression.equals(to: rhs.expression)
    }
    
    var debugDescription: String {
        let c = PrintCursors ? " \(range)" : ""
        return "[Assign\(c) \(receiver)\n        = \(expression)]"
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

    func makeCopy() -> Assignment {
        Assignment(receiver: receiver.makeCopy(), expression: expression.makeCopy(), range: range)
    }
}
