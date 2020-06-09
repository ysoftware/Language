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
            let lineNumber = le.startCursor.lineNumber
            print("Unexpected lexer error on line \(lineNumber)\n")
            
            // @Todo use endCursor
            
            let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
            if lineNumber >= 3 { print("   >    \(lines[lineNumber-3])") }
            if lineNumber >= 2 { print("   >    \(lines[lineNumber-2])") }
            print("   >    \(lines[lineNumber-1])")
            print("        \(String(repeating: " ", count: le.startCursor.character + 1))^")
            
            print("")
            print(le.message.rawValue, "\n")
            exit(1)
        }
        else if let pe = error as? ParserError {
            let lineNumber = pe.startCursor.lineNumber
            print("Unexpected parser error on line \(lineNumber)")
            if let c = pe.context { print("Context: \(c)") }
            print("")
        
            let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
            if lineNumber >= 3 { print("   >    \(lines[lineNumber-3])") }
            if lineNumber >= 2 { print("   >    \(lines[lineNumber-2])") }
            print("   >    \(lines[lineNumber-1])")

//            NSLog("\u{001B}[0;33mhello")
            
            if pe.startCursor.lineNumber == pe.endCursor.lineNumber {
                let startCursor = String(repeating: " ", count: pe.startCursor.character) + "^"
                let endCursor = String(repeating: "^", count: pe.endCursor.character-pe.startCursor.character)
                print("        \(startCursor)\(endCursor)")
            }
            else {
                // multiline expression error
                print(String(repeating: "^", count: pe.endCursor.character))
            }
            
            print("")
            print(pe.message, "\n")
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
