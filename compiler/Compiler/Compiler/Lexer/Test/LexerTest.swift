//
//  LexerTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let PRINT_PASSES = false

class LexerTest {
    fileprivate var failed = 0
    
    static func run() {
        let i = LexerTest()
        i.failed = 0
        
        i.testMultilineStringLiteral()
        i.testMultilineStringLiteralFail3()
        i.testMultilineStringLiteralFail2()
        i.testMultilineStringLiteralFail()
        i.testStingLiteralFail3()
        i.testStingLiteralFail2()
        i.testStringLiteralFail()
        i.testStringLiteral()
        i.testDirective()
        i.testDirectiveFail3()
        i.testDirectiveFail2()
        i.testDirectiveFail()
        i.testComments()
        i.testNumbersFail2()
        i.testNumbersFail()
        i.testVarargsRangeSpecialFloat()
        i.testBrackets()
        i.testFunctionDeclaration()
        i.testNumbers()
        
        if i.failed != 0 {
            print("❌ \(i.failed) lexer test\(i.failed == 1 ? "" : "s") have failed!")
        }
        else {
            print("All lexer tests have passed.\n")
        }
    }
    
    func printErrorCase(caseName: String = #function, _ code: String,
                        _ resultR: Result<[Token], LexerError>, _ expected: LexerError) {
        
        switch resultR {
        case .failure(let error):
            if error.message == expected.message {
                guard PRINT_PASSES else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)")
                return
            }
            failed += 1
            print("❌ \(caseName)")
            print("code: \"\(code)\"")
            print("Expected error:", expected.message)
            print("Received error:", error.message.rawValue)
            print("\n\n")
            
        case .success(let tokens):
            failed += 1
            print("❌ \(caseName)")
            print("code: \"\(code)\"")
            print("Expected error:", expected.message, "\n===")
            printTokens(tokens)
            print("===\n\n")
        }
    }
    
    func printResultCase(caseName: String = #function, _ code: String,
                         _ resultR: Result<[Token], LexerError>, _ expect: [Token]) {
        
        switch resultR {
        case .failure(let error):
            failed += 1
            print("\n❌ \(caseName)\nUnexpected error on line \(error.cursor.lineNumber):",
                error.message.rawValue, "\n")
            let line = code.split(separator: "\n")[error.cursor.lineNumber-1]
            print("\"\(line)\"")
            print("\(String(repeating: "_", count: error.cursor.character + 1))^")
            print("\n\n")
            
        case .success(let result):
            if result != expect {
                failed += 1
                print("\n❌ \(caseName)")
                print("\"\(code)\"")
                if result.count != expect.count {
                    print("Counts don't match", result.count, "vs expected", expect.count, "\n===")
                    printTokens(result)
                    print("===\n\n")
                }
                else {
                    for i in 0..<result.count {
                        if result[i] != expect[i] {
                            print("Mismatch in \(i):", result[i], "expected", expect[i], "\n\n")
                        }
                    }
                }
            }
            else {
                guard PRINT_PASSES else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)")
            }
        }
    }
    
    private func printTokens(_ tokens: [Token]) {
        print(tokens.map { String(describing: $0) }.joined(separator: "\n"))
    }
}
