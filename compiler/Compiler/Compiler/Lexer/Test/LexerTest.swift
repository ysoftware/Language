//
//  LexerTest.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 21.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class LexerTest {
    fileprivate var failed = 0
    
    static func run() {
        let i = LexerTest()
        i.failed = 0
        
        i.testNumbersFail4()
        i.testComments()
        i.testInvalidIdentifierUnderscore()
        i.testCursors()
        i.testBoolLiteral()
        i.testNumbersFail3()
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
        i.testNumbersFail2()
        i.testNumbersFail()
        i.testVarargsRangeSpecialFloat()
        i.testBrackets()
        i.testFunctionDeclaration()
        i.testNumbers()
        
        if i.failed != 0 { print("\(i.failed) lexer test\(plural(i.failed)) have failed!\n".color(.lightRed)) }
        else { print("All lexer tests have passed.\n".color(.lightGreen)) }
    }
    
    func printErrorCase(caseName: String = #function, _ code: String,
                        _ resultR: Result<LexerOutput, LexerError>, _ expected: LexerError) {
        
        // @Todo: test exact cursors
        
        switch resultR {
        case .failure(let error):
            if expected.message == error.message {
                guard PrintPasses else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)".color(.darkGray))
                return
            }
            failed += 1
            print("\(caseName)".color(.lightRed))
            print("code: \"\(code)\"".color(.cyan))
            print("Expected error:", expected.message)
            print("Received error:", error.message.rawValue)
            print("\n\n")
            
        case .success(let output):
            failed += 1
            print("\(caseName)".color(.lightRed))
            print("code: \"\(code)\"".color(.cyan))
            print("Expected error:", expected.message, "\n===".color(.darkGray))
            printTokens(output.tokens)
            print("===\n\n".color(.darkGray))
        }
    }
    
    func printResultCase(caseName: String = #function, _ code: String,
                         _ resultR: Result<LexerOutput, LexerError>, _ expect: [Token]) {
        
        switch resultR {
        case .failure(let error):
            failed += 1
            print("\n\(caseName)\nUnexpected error on line \(error.startCursor.lineNumber)".color(.lightRed))
            print(error.message.rawValue, "\n")
            
            // @Todo use endCursor
                
            let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
            let line = lines[error.endCursor.lineNumber-1]
            print("\"\(line)\"")
            print("\(String(repeating: "_", count: error.startCursor.character + 1))^")
            print("\n\n")
            
        case .success(let output):
            if output.tokens != expect {
                failed += 1
                print("\n\(caseName)".color(.lightRed))
                print("\"\(code)\"".color(.cyan))
                if output.tokens.count != expect.count {
                    print("Counts don't match:".color(.lightGray),
                          output.tokens.count,
                          "Expected:".color(.lightGray),
                          expect.count,
                          "\n===".color(.darkGray))
                    
                    printTokens(output.tokens)
                    print("===\n\n".color(.darkGray))
                }
                else {
                    for i in 0..<output.tokens.count {
                        if expect[i] != output.tokens[i] {
                            print("Mismatch in \(i):\n".color(.lightGray),
                                  output.tokens[i],
                                  "\nExpected:\n".color(.lightGray),
                                  expect[i],
                                  "\n\n")
                        }
                    }
                }
            }
            else {
                guard PrintPasses else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)".color(.lightGray))
            }
        }
    }
    
    private func printTokens(_ tokens: [Token]) {
        print(tokens.map { String(describing: $0) }.joined(separator: "\n"))
    }
}

func asTokens(_ values: [TokenValue]) -> [Token] {
    values.map { Token($0) }
}
