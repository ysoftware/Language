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
    .map { String($0[$0.index($0.startIndex, offsetBy: 4)..<$0.endIndex]) }
    .flatMap { Int($0) } ?? 0

let asts = [
    IfElse(false),  // 0
    IfElse(true),   // 1
    ForLoop,        // 2
]

let ast = asts[index]
let ir = IR().generateIR(globalScope: ast)

print(ir)
print("\n")
