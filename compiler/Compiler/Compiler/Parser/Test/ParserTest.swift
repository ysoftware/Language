//
//  ParserTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let PRINT_PASSES = true

class ParserTest {
    fileprivate var failed = 0
    
    static func run() {
        let i = ParserTest()
        i.failed = 0
        
        i.testFunctionDeclaration()
        
        if i.failed != 0 {
            print("❌ \(i.failed) parser test\(i.failed == 1 ? "" : "s") have failed!")
        }
        else {
            print("All parser tests have passed.")
        }
    }
    
    func printErrorCase() {
        
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Scope, ParserError>, _ expect: Scope) {
        
    }
}
