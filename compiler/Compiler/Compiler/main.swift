//
//  main.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let asts = [
    IfElse(true),   // 0
    IfElse(false),  // 1
    ForLoop,        // 2
]

let ast = asts[2]
let ir = IR().generateIR(globalScope: ast)

print(ir)
print("\n")
