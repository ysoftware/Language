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
        let code = "func printf(format: String, arguments: Int32, ...) { if (true) { } }"
        let tokens = try! lexerAnalyze(code).get()
        let result = parse(tokens)
        
        printResultCase(code, result, Scope(code: [
            ProcedureDeclaration(
                id: "global_func_printf",
                name: "printf",
                arguments: [.string, .int],
                returnType: .void, flags: [.isVarargs, .isForeign],
                scope: .empty)
        ]))
    }
}
