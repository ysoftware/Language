//
//  Expression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class VariableDeclaration: Statement {
    
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let isConstant  = Flags(rawValue: 1 << 0)
    }
    
    let id: String
    let expType: Type
    let flags: Flags
    let expression: Expression
    
    internal init(id: String, expType: Type, flags: VariableDeclaration.Flags, expression: Expression) {
        self.id = id
        self.expType = expType
        self.flags = flags
        self.expression = expression
    }
}

class VariableAssignment: Statement {
    
    let receiverId: String
    let expression: Expression
    
    internal init(receiverId: String, expression: Expression) {
        self.receiverId = receiverId
        self.expression = expression
    }
}

class BinaryOperator: Expression {
    
    let name: Instruction
    let operatorType: Type
    let expType: Type
    let arguments: (Expression, Expression)

    internal init(name: Instruction, operatorType: Type, expType: Type, arguments: (Expression, Expression)) {
        self.name = name
        self.operatorType = operatorType
        self.expType = expType
        self.arguments = arguments
    }
}

class Return: Statement {
    
    let value: Expression
    
    internal init(value: Expression) {
        self.value = value
    }
}
