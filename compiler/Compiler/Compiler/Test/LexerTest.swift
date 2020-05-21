//
//  LexerTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation
    
    fileprivate let code = """
func printf(format: String, arguments: Int32, ...) #foreign;

func main() -> Int32 {
    a: Int = 0;
    outerLoop: while true {
        while true {
            a = a + 1;
            if a > 500 { break outerLoop; }
            if a == 100 { break; }
            if a > 1 { continue; }
            else { printf("Did not continue! a is %d\n\", a); }
        }
        printf("Broke out of loop 1, a is %d\n\", a);
    }
    printf("Broke out of loop 2, a is %d\n\", a);
}
"""

func lexerTest() {

    lexerFirstTest()
}


func lexerFirstTest() {
    
    let lexer = Lexer()
    let result = lexer.analyze("Int32, ..., .1234, A..z")
    
    let expect: [Token] = [
        .identifier(name: "Int32"),
        .separator(symbol: ","),
        .punctuator(character: "..."),
        .separator(symbol: ","),
        .literal(value: .float(value: 0.1234)),
        .separator(symbol: ","),
        .identifier(name: "A"),
        .punctuator(character: ".."),
        .identifier(name: "z")
    ]
    
    assert(result == expect)
}
