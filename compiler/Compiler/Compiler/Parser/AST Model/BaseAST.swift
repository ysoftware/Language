//
//  BaseAST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Scope: Ast {
    
    var debugDescription: String {
        var string = "[Scope] \(code.count) statement(s)"
        for statement in code {
            string.append("\n\t\(statement.debugDescription)")
        }
        return string
    }
    
    var code: [Statement]
    
    static let empty = Scope(code: [])
    var isEmpty: Bool { code.isEmpty }
    
    internal init(code: [Statement]) {
        self.code = code
    }
}

class Value: Expression {
    
    var debugDescription: String {
        "[Value] \(name) of type \(expType)"
    }
    
    var name: String
    var expType: Type
    
    internal init(name: String, expType: Type) {
        self.name = name
        self.expType = expType
    }
}

protocol Ast: class, CustomDebugStringConvertible { }

protocol Literal: Ast { }

protocol Statement: Ast { }

protocol Expression: Ast {
    var expType: Type { get }
}

protocol Declaration: Ast {
    var name: String { get }
}
