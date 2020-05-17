//
//  AST.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct StringLiteral: Expression {

    let type = Type(name: "String")
    
    let id: String
    let value: String
}

struct IntLiteral: Expression {
    
    let type = Type(name: "Int32")
    
    let id: String?
    let value: Int32
}

