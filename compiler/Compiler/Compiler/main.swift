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
    .flatMap { Int($0) } ?? 3

let asts = [
    /* 0 */ IfElseAST(false),
    /* 1 */ IfElseAST(true),
    /* 2 */ ForLoopAST,
    /* 3 */ LoopBreakContinueAST,
]

let ast = asts[index]
let ir = IR().generateIR(globalScope: ast)

print(ir)
print("\n")
