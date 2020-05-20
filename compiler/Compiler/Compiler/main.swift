//
//  main.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation


//let index: Int = CommandLine.arguments
//    .first { $0.starts(with: "-ast") }
//    .map { String($0[$0.index($0.startIndex, offsetBy: 4)..<$0.endIndex]) }
//    .flatMap { Int($0) } ?? 3
//
//let asts = [
//    /* 0 */ IfElseAST(false),
//    /* 1 */ IfElseAST(true),
//    /* 2 */ WhileLoopAST,
//    /* 3 */ LoopBreakContinueAST,
//]
//
//let ast = asts[index]
//let ir = IR().generateIR(globalScope: ast)
//
//print(ir)
//print("\n")



let code = """
func printf(format: String, arguments: Int32, ...) #foreign
func main() -> Int32 {
    a: Int = 0
    outerLoop: while true {
        while true {
            a = a + 1
            if a > 500 { break outerLoop }
            if a == 100 { break }
            if a > 1 { continue }
            else { printf("Did not continue! a is %d\n\", a) }
        }
        printf("Broke out of loop 1, a is %d\n\", a)
    }
    printf("Broke out of loop 2, a is %d\n\", a)
}
"""

class O: LexerOutput {
    func lexerFinished(_ instance: Lexer) { }
    func lexer(_ instance: Lexer, didGenerateToken token: Token) { print(token) }
}

let lexer = Lexer()
let output = O()
lexer.output = output

lexer.analyze(code)
