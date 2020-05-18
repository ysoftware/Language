//
//  main.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let asts = [
    IfElse,     // 0
    ForLoop,    // 1
]

let ast = asts[1]
let ir = IR().generateIR(globalScope: ast)

print(ir)
print("\n")
