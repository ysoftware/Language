//
//  Expression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct VariableDeclaration: Expression, Declaration {
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let isConstant    = Flags(rawValue: 1 << 0)
    }
    
    let id: String
    let type: Type
    let flags: Flags
    let expression: Expression
}

struct VariableAssignment: Expression {
    
    let type: Type = .void
    let receiverId: String
    let expression: Expression
}

struct BinaryOperator: Expression {
    
    let name: String
    let type: Type
    let arguments: (Expression, Expression)
}

struct Return: Expression {
    
    let type: Type = .void
    let value: Expression
}
