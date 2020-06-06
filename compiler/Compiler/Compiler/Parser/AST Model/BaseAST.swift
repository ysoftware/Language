//
//  BaseAST.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Code: Ast, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: Code, rhs: Code) -> Bool {
        lhs.statements.elementsEqual(rhs.statements) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        var string = "[Scope] \(statements.count) statement(s)"
        for statement in statements {
            string.append("\n\t\(statement.debugDescription)")
        }
        return string
    }
    
    var statements: [Statement]
    
    static let empty = Code([])
    var isEmpty: Bool { statements.isEmpty }
    
    internal init(_ code: [Statement]) {
        self.statements = code
    }
}

/// A variable or constant passed by name.
class Value: Expression, Equatable {
    
    var startCursor = Cursor()
    var endCursor = Cursor()
    
    static func == (lhs: Value, rhs: Value) -> Bool {
        lhs.name == rhs.name
            && lhs.exprType == rhs.exprType
    }
    
    var debugDescription: String {
        "[Value] \(name): \(exprType)"
    }
    
    var name: String
    var exprType: Type
    
    internal init(name: String, exprType: Type) {
        self.name = name
        self.exprType = exprType
    }
}

protocol Ast: class, CustomDebugStringConvertible {
    
    var startCursor: Cursor { get set }
    var endCursor: Cursor { get set }
}

protocol Statement: Ast { }

protocol Expression: Ast {
    
    var exprType: Type { get set }
}

protocol Declaration: Ast {
    var name: String { get }
}

protocol LiteralExpr: Expression { }
