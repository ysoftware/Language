//
//  LexerTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation
    
func lexerTest() {
    print("Testing the lexer...")
    // parsed
    lexer_testVarargsRangeSpecialFloat()
    lexer_testBrackets()
    lexer_testFunctionDeclaration()
    lexer_testNumbers()
    // errored
    lexer_testNumbersFail()
    print("Lexer tests done.")
}

func printLexerTestFail(caseName: String = #function,  _ code: String,
                        _ resultR: Result<[Token], LexerError>, _ expected: LexerError) {
    
    switch resultR {
    case .failure(let error):
        if error.message == expected.message {
            print("OK \(caseName)")
            return
        }
        print("❌ \(caseName)")
        print("code: \"\(code)\"")
        print("Expected error:", expected.message)
        print("Received error:", error.message)
        print("\n\n")
        
    case .success(let tokens):
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
        print("\n❌ \(caseName)\n")
        print("\"\(code)\"")
        // @Todo: print the line at error.lineNumber, ignore for now
        print("\(String(repeating: "_", count: error.character + 1))^")
        print("Error:", error.message)
        print("\n\n")

    case .success(let result):
        if result != expect {
            print("❌ \(caseName)")
            print("\"\(code)\"")
            if result.count != expect.count {
                print("counts don't match", result.count, "vs expected", expect.count, "\n===")
                printTokens(result)
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
            print("OK \(caseName)")
        }
    }
}

private func printTokens(_ tokens: [Token]) {
    print(tokens.map { String(describing: $0) }.joined(separator: "\n"))
}
