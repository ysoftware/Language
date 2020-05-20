//
//  StatementContext.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 19.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

protocol StatementContext { }

struct LoopContext: StatementContext {
    
    /// label name in code
    let userLabel: String?
    
    /// label in IR to br to on break
    let breakLabel: String
    
    /// label in IR to br to on continue
    let continueLabel: String
}

func example() {
    
    label1: for _ in 0..<15 {
        label2: for _ in 0..<10 {
            break label1
        }
    }
    
    for _ in 0..<15 {
        var shouldBreak1 = false
        for _ in 0..<10 {
            shouldBreak1 = true
        }
        if shouldBreak1 { break }
    }
}
