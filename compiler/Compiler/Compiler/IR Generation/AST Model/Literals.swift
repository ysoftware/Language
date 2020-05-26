//
//  AST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct StringLiteral: Expression, Literal {

    let expType: Type = .string
    let value: String
}

struct IntLiteral: Expression, Literal {
    
    // @Todo: make it choose the type appropriately depending on value
    let expType: Type = .int
    let value: Int
}

struct FloatLiteral: Expression {

    let expType: Type = .float
    let value: Float32
}

struct BoolLiteral: Expression, Literal {
    
    let expType: Type = .bool
    let value: Bool
}
