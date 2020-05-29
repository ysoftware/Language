//
//  ParserTest.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let PRINT_PASSES = true

class ParserTest {
    fileprivate var failed = 0
    
    static func run() {
        let i = ParserTest()
        i.failed = 0
        
        i.testFunctionDeclaration()
        i.testStructDeclaration()
        i.testVariableDeclaration()
        
        if i.failed != 0 { print("❌ \(i.failed) parser test\(i.failed == 1 ? "" : "s") have failed!") }
        else { print("All parser tests have passed.") }
    }
    
    func printErrorCase() {
        
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Scope, ParserError>, _ expect: Scope) {
        
        switch resultAST {
        case .failure(let error):
            failed += 1
            print("\n❌ \(caseName)\nUnexpected error on line \(error.cursor.lineNumber):",
                error.message.rawValue, "\n")
            
            // @Todo: print 3 lines (before, current and after)
            let line = code.split(separator: "\n")[error.cursor.lineNumber-1]
            print("\"\(line)\"\n")
            print("\(String(repeating: "_", count: error.cursor.character + 1))^")
            print("\n\n")
        case .success(let result):
            if !result.equals(to: expect) {
                failed += 1
                print("\n❌ \(caseName)")
                print("\"\(code)\"\n")
                if result.code.count != expect.code.count {
                    print("Counts don't match", result.code.count, "vs expected", expect.code.count, "\n===")
                    print(result)
                    print("===\n\n")
                }
                else {
                    for i in 0..<result.code.count {
                        if !expect.equals(to: result) {
                            print("Mismatch in:\n", result.code[i], "\nExpected:\n", expect.code[i], "\n\n")
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
