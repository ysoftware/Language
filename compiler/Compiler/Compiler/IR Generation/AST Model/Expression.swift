//
//  Expression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct VariableDeclaration: Statement {
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let isConstant    = Flags(rawValue: 1 << 0)
    }
    
    let id: String
    let expType: Type
    let flags: Flags
    let expression: Expression
}

struct VariableAssignment: Statement {
    
    let receiverId: String
    let expression: Expression
}

struct BinaryOperator: Expression {
    
    let name: Operator
    let operatorType: Type
    let expType: Type
    let arguments: (Expression, Expression)
}

struct Return: Statement {
    
    let value: Expression
}
