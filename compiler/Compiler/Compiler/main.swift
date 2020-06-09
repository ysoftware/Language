//
//  main.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let PRINT_PASSES = false

if let i = CommandLine.arguments.firstIndex(of: "-file") {
    guard CommandLine.arguments.count > i + 1 else {
        print("usage: ./compiler -file <filename> (-run)")
        exit(1)
    }
    
    let code: String
    do {
        let filePath = CommandLine.arguments[i + 1]
        code = try String(contentsOfFile: filePath, encoding: .utf8)
    }
    catch {
        print(error.localizedDescription)
        exit(1)
    }
    
    do {
        let tokens = try Lexer(code).analyze().get()
        let result = try Parser(tokens).parse().get()
        let ir = IR().generateIR(globalScope: result)
        
        do {
            let appname = "output"
            try compileAndSave(ir: ir, output: appname)
            
            if CommandLine.arguments.contains("-run") {
                let output = try runCommand("./\(appname).app", [])
                print(output)
            }
            exit(0)
        }
        catch {
            print(error.localizedDescription)
            exit(1)
        }
    }
    catch {
        if let le = error as? LexerError {
            print("Unexpected error on line \(le.startCursor.lineNumber)")
            print(le.message.rawValue, "\n")
            
            // @Todo use endCursor
            
            let lines = code.components(separatedBy: .newlines)
            let line = lines[le.startCursor.lineNumber-1]
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
            print(error.localizedDescription)
            exit(1)
        }
    }
}

// no arguments
LexerTest.run()
ParserTest.run()
