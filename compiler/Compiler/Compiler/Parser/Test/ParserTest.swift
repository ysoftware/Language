//
//  ParserTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let PRINT_PASSES = false

class ParserTest {
    fileprivate var failed = 0
    
    static func run() {
        let i = ParserTest()
        i.failed = 0
        
        i.testTypeInferenceLocal2()
        i.testWhileLoop()
        i.testTypeInference2()
        i.testTypeInference()
        i.testTypeInferenceGlobalProc()
        i.testVariableDeclaration()
        i.testFunctionDeclaration()
        i.testStructDeclaration()
        
        if i.failed != 0 { print("❌ \(i.failed) parser test\(plural(i.failed)) have failed!") }
        else { print("All parser tests have passed.") }
    }
    
    func printErrorCase() {
        
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Code, ParserError>, _ expect: Code) {
        
        switch resultAST {
        case .failure(let error):
            failed += 1
            print("\n❌ \(caseName)\nUnexpected error on line \(error.startCursor.lineNumber):",
                error.message, "\n")
            
            _ = {
                let lines = code.split(separator: "\n")
                let line = lines[error.endCursor.lineNumber-1]
                print("\(line)\n")
                if error.startCursor.lineNumber == error.endCursor.lineNumber
                    && error.startCursor.character != error.endCursor.character {
                    
                    let startCursor = String(repeating: "_", count: error.startCursor.character) + "^"
                    let endCursor = String(repeating: "_", count: error.endCursor.character-error.startCursor.character-1) + "^"
                    print("\(startCursor)\(endCursor)")
                }
                else {
                    print(String(repeating: "_", count: error.endCursor.character) + "^")
                }
                print("\n\n")
            }()
            
        case .success(let result):
            if !result.equals(to: expect) {
                failed += 1
                print("\n❌ \(caseName)")
                print("\"\(code)\"\n")
                if result.statements.count != expect.statements.count {
                    print("Counts don't match", result.statements.count, "vs expected", expect.statements.count, "\n===")
                    print(result)
                    print("===\n\n")
                }
                else {
                    for i in 0..<result.statements.count {
                        if !expect.equals(to: result) {
                            print("Mismatch in:\n", result.statements[i], "\nExpected:\n", expect.statements[i], "\n\n")
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
}
