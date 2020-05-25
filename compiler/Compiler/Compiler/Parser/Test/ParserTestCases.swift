//
//  ParserTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension ParserTest {
    
    func testFunctionDeclaration() {
        let code = "func printf(format: String, arguments: Int32, ...) -> Void #foreign"
        let tokens = try! lexerAnalyze(code).get()
        
        printResultCase(code, parse(tokens), Scope(code: [
            ProcedureDeclaration(
                id: "global_func_printf",
                name: "printf",
                arguments: [.string, .int],
                returnType: .void, flags: [.isVarargs, .isForeign],
                scope: .empty)
        ]))
    }
}
