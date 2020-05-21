//
//  LexerTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation
    
func lexerTest() {

    lexer_testVarargsRangeSpecialFloat()
    lexer_testBrackets()
}

func lexer_testBrackets() {
    let lexer = Lexer()
    let result = lexer.analyze("I[aZ]a(saw)d")
    
    let expect: [Token] = [
        .identifier(name: "I"),
        .punctuator(character: "["),
        .identifier(name: "aZ"),
        .punctuator(character: "]"),
        .identifier(name: "a"),
        .punctuator(character: "("),
        .identifier(name: "saw"),
        .punctuator(character: ")"),
        .identifier(name: "d")
    ]
    
    printLexerTestResult(expect, result)
}

func lexer_testVarargsRangeSpecialFloat() {
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
        .identifier(name: "z"),
    ]
    
    printLexerTestResult(expect, result)
}

func printLexerTestResult(caseName: String = #function, _ expect: [Token], _ result: [Token]) {
    
    if result != expect {
        print("\n\(caseName): ❌")
        if result.count != expect.count {
            print("counts don't match", result.count, "vs expected", expect.count, "\n===")
            print(result.map { String(describing: $0) }.joined(separator: "\n"))
        }
        else {
            for i in 0..<result.count {
                if result[i] != expect[i] {
                    print(i, result[i], "expected", expect[i])
                }
            }
        }
        print("===\n\n")
    }
    else {
        print("\(caseName): ✅")
    }
}

//    fileprivate let code = """
//func printf(format: String, arguments: Int32, ...) #foreign;
//
//func main() -> Int32 {
//    a: Int = 0;
//    outerLoop: while true {
//        while true {
//            a = a + 1;
//            if a > 500 { break outerLoop; }
//            if a == 100 { break; }
//            if a > 1 { continue; }
//            else { printf("Did not continue! a is %d\n\", a); }
//        }
//        printf("Broke out of loop 1, a is %d\n\", a);
//    }
//    printf("Broke out of loop 2, a is %d\n\", a);
//}
//"""
