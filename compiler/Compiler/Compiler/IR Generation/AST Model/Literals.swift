//
//  AST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class StringLiteral: Expression, Literal {
    
    internal init(value: String) {
        self.value = value
    }

    let expType: Type = .string
    let value: String
}

class IntLiteral: Expression, Literal {
    
    internal init(value: Int) {
        self.value = value
    }

    // @Todo: make it choose the type appropriately depending on value
    let expType: Type = .int
    let value: Int
}

class FloatLiteral: Expression {
    
    internal init(value: Float32) {
        self.value = value
    }
    
    let expType: Type = .float
    let value: Float32
}

class BoolLiteral: Expression, Literal {
    
    internal init(value: Bool) {
        self.value = value
    }
    
    let expType: Type = .bool
    let value: Bool
}
