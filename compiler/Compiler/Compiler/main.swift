//
//  main.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let index: Int = CommandLine.arguments
    .first { $0.starts(with: "-ast") }
    .map { var a = $0; a.removeFirst(4); return a }
    .flatMap { Int($0) } ?? 0

let asts = [
    IfElse(true),   // 0
    IfElse(false),  // 1
    ForLoop,        // 2
]

let ast = asts[index]
let ir = IR().generateIR(globalScope: ast)

print(ir)
print("\n")
