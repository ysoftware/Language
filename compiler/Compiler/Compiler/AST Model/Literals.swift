//
//  AST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct StringLiteral: Statement {

    let type: Type = .string
    let id: String
    let value: String
}

struct IntLiteral: Expression {
    
    let expType: Type = .int
    let value: Int32
}

struct BoolLiteral: Expression {
    
    let expType: Type = .bool
    let value: Bool
}
