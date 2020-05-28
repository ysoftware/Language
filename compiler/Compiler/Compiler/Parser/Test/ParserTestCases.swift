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
        let code = "func printf(format: String, arguments: Int32, ...) { a: String; b :: 1; }"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
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
