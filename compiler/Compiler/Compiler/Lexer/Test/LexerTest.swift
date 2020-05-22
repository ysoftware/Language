//
//  LexerTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let PRINT_PASSES = false
fileprivate var failed = false
    
func lexerTest() {
    failed = false
    
    lexer_testDirective()
    lexer_testDirectiveFail3()
    lexer_testDirectiveFail2()
    lexer_testDirectiveFail()
    lexer_testMultilineStringLiteralFail2()
    lexer_testMultilineStringLiteralFail()
    lexer_testMultilineStringLiteral()
    lexer_testStringLiteralFail()
    lexer_testStringLiteral()
    lexer_testComments()
    lexer_testNumbersFail2()
    lexer_testNumbersFail()
    lexer_testVarargsRangeSpecialFloat()
    lexer_testBrackets()
    lexer_testFunctionDeclaration()
    lexer_testNumbers()

    if failed {
        print("❌ Some lexer tests have failed!")
    }
    else {
        print("All lexer tests have passed.\n")
    }
}

func printLexerTestFail(caseName: String = #function,  _ code: String,
                        _ resultR: Result<[Token], LexerError>, _ expected: LexerError) {
    
    switch resultR {
    case .failure(let error):
        if error.message == expected.message {
            guard PRINT_PASSES else { return }
            print("OK \(caseName)")
            return
        }
        failed = true
        print("❌ \(caseName)")
        print("code: \"\(code)\"")
        print("Expected error:", expected.message)
        print("Received error:", error.message)
        print("\n\n")
        
    case .success(let tokens):
        failed = true
        print("❌ \(caseName)")
        print("code: \"\(code)\"")
        print("Expected error:", expected.message, "\n===")
        printTokens(tokens)
        print("===\n\n")
    }
}

func printLexerTestResult(caseName: String = #function, _ code: String,
                          _ resultR: Result<[Token], LexerError>, _ expect: [Token]) {
    
    switch resultR {
    case .failure(let error):
        failed = true
        print("\n❌ \(caseName)\n")
        print("\"\(code)\"")
        // @Todo: print the line at error.lineNumber, ignore for now
        print("\(String(repeating: "_", count: error.character + 1))^")
        print("Error:", error.message)
        print("\n\n")

    case .success(let result):
        if result != expect {
            failed = true
            print("\n❌ \(caseName)")
            print("\"\(code)\"")
            if result.count != expect.count {
                print("counts don't match", result.count, "vs expected", expect.count, "\n===")
                printTokens(result)
                print("===\n\n")
            }
            else {
                for i in 0..<result.count {
                    if result[i] != expect[i] {
                        print("mismatch in \(i):", result[i], "expected", expect[i], "\n\n")
                    }
                }
            }
        }
        else {
            guard PRINT_PASSES else { return }
            print("OK \(caseName)")
        }
    }
}

private func printTokens(_ tokens: [Token]) {
    print(tokens.map { String(describing: $0) }.joined(separator: "\n"))
}
