//
//  main.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let PRINT_PASSES = false


if CommandLine.arguments.count == 3 {
    // -file <path>
    
    if CommandLine.arguments[1] == "-file" {
        let code: String
        do {
            let filePath = CommandLine.arguments[2]
            code = try String(contentsOfFile: filePath, encoding: .utf8)
        }
        catch {
            print(error)
            exit(1)
        }
        
        do {
            let tokens = try Lexer(code).analyze().get()
            let result = try Parser(tokens).parse().get()
            let ir = IR().generateIR(globalScope: result)
            
            // @Todo: run lli from here
            
            print(ir, "\n")
            exit(0)
        }
        catch {
            if let le = error as? LexerError {
                print("Unexpected error on line \(le.startCursor.lineNumber)")
                print(le.message.rawValue, "\n")
                
                // @Todo use endCursor
                
                let line = code.split(separator: "\n")[le.startCursor.lineNumber-1]
                print("\"\(line)\"")
                print("\(String(repeating: "_", count: le.startCursor.character + 1))^")
                print("\n\n")
                exit(1)
            }
            else if let pe = error as? LexerError {
                let lines = code.split(separator: "\n")
                let line = lines[pe.endCursor.lineNumber-1]
                print("\(line)")
                if pe.startCursor.lineNumber == pe.endCursor.lineNumber {
                    let startCursor = String(repeating: " ", count: pe.startCursor.character) + "^"
                    let endCursor = String(repeating: "^", count: pe.endCursor.character-pe.startCursor.character)
                    print("\(startCursor)\(endCursor)")
                }
                else {
                    // multiline expression error
                    print(String(repeating: "^", count: pe.endCursor.character))
                }
                print("\n\n")
                exit(1)
            }
            else {
                print(error)
                exit(1)
            }
        }

        print("usage: ./compiler -file <filename>")
        exit(1)
    }
}

if CommandLine.arguments.count > 1 && CommandLine.arguments[1].starts(with: "-ast") {
    let index: Int = CommandLine.arguments
        .first { $0.starts(with: "-ast") }
        .map { String($0[$0.index($0.startIndex, offsetBy: 4)..<$0.endIndex]) }
        .flatMap { Int($0) } ?? 3
    
    let asts = [
        /* 0 */ IfElseAST(false),
        /* 1 */ IfElseAST(true),
        /* 2 */ WhileLoopAST,
        /* 3 */ LoopBreakContinueAST,
    ]
    
    let ast = asts[index]
    let ir = IR().generateIR(globalScope: ast)
    
    // @Todo: run lli from here
    
    print(ir)
    print("\n")
    exit(0)
}

// no arguments
LexerTest.run()
ParserTest.run()
