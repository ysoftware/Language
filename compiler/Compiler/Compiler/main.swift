//
//  main.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let startTime = CFAbsoluteTimeGetCurrent()
var previousTime = startTime

let PRINT_PASSES = false
let ColorCode = !CommandLine.arguments.contains("--no-color")

if let i = CommandLine.arguments.firstIndex(of: "-file") {
    guard CommandLine.arguments.count > i + 1 else {
        print("usage: ./compiler -file <filename> (-run)")
        quit(1)
    }
    
    let code: String
    do {
        let filePath = CommandLine.arguments[i + 1]
        code = try String(contentsOfFile: filePath, encoding: .utf8)
    }
    catch {
        print(error.localizedDescription)
        quit(1)
    }
    
    do {
        let tokens = try Lexer(code).analyze().get()
        reportTimeSpent(on: "Lexing", from: previousTime)
        let result = try Parser(tokens).parse().get()
        reportTimeSpent(on: "Parsing", from: previousTime)
        let ir = IR().generateIR(globalScope: result)
        reportTimeSpent(on: "IR Generation", from: previousTime)

        if CommandLine.arguments.contains("-ast") {
            print(result)
            reportTimeSpent()
            quit(0)
        }
        
        do {
            let appname = "output"
            try compileAndSave(ir: ir, output: appname)
            
            if CommandLine.arguments.contains("-run") {
                let output = try runCommand("/usr/local/opt/llvm/bin/lli", ["\(appname).ll"])
                reportTimeSpent(on: "Running", from: previousTime)
                outputCommand("PROGRAM", output)
            }
            quit(0)
        }
        catch {
            print(error.localizedDescription)
            quit(1)
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
            
            if !ColorCode {
                print("   >    \(lines[lineNumber-1])")
                print("        \(String(repeating: " ", count: le.startCursor.character + 1))^")
            }
            else {
                print("   >    \(lines[lineNumber-1])")
                print("        \(String(repeating: " ", count: le.startCursor.character + 1))^")
            }
            
            print("")
            print(le.message.rawValue, "\n")
            quit(1)
        }
        else if let pe = error as? ParserError {
            // @Todo: refactor out and clean up
            
            let lineNumber = pe.startCursor.lineNumber
            print("Unexpected parser error on line \(lineNumber)")
            if let c = pe.context { print("Context: \(c)") }
            print("")
        
            let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
            if lines.count > lineNumber-3, lineNumber >= 3 { print("   >    \(lines[lineNumber-3])") }
            if lines.count > lineNumber-2, lineNumber >= 2 { print("   >    \(lines[lineNumber-2])") }

            if !ColorCode {
                print("   >    \(lines[lineNumber-1])")
                if pe.startCursor.lineNumber == pe.endCursor.lineNumber {
                    let startCursor = String(repeating: " ", count: pe.startCursor.character) + "^"
                    let endCursor = String(repeating: "^", count: pe.endCursor.character-pe.startCursor.character)
                    print("        \(startCursor)\(endCursor)")
                }
                else {
                    print(String(repeating: "^", count: pe.endCursor.character))
                }
            }
            else {
                let errorLine = lines[lineNumber-1]
                
                if pe.startCursor.lineNumber == pe.endCursor.lineNumber, pe.endCursor.character <= errorLine.count {
                    
                    let start = errorLine.index(errorLine.startIndex, offsetBy: pe.startCursor.character)
                    let end = errorLine.index(errorLine.startIndex, offsetBy: pe.endCursor.character)
                    
                    let end2: String.Index
                    let error: Substring
                    if errorLine.count <= pe.endCursor.character {
                        end2 = errorLine.endIndex
                         error = errorLine[start..<end]
                    }
                    else {
                        end2 = errorLine.index(errorLine.startIndex, offsetBy: pe.endCursor.character + 1)
                        error = errorLine[start...end]
                    }

                    let beforeError = errorLine[errorLine.startIndex..<start]
                    let afterError = errorLine[end2..<errorLine.endIndex]
                    print("   >    \(String(beforeError))\u{001B}[0;31m\(String(error))\u{001B}[0;0m\(String(afterError))")
                    let startCursor = String(repeating: " ", count: pe.startCursor.character) + "^"
                    let endCursor = String(repeating: "^", count: pe.endCursor.character-pe.startCursor.character)
                    print("        \u{001B}[0;31m\(startCursor)\(endCursor)\u{001B}[0;0m")
                }
                else {
                    print("Error @ \(pe.startCursor) - \(pe.endCursor)")
                    print(">>>>> Unable to point to the error cursor.")
                }
            }
            
            print("")
            print(pe.message, "\n")
            quit(1)
        }
        else {
            print(error.localizedDescription)
            quit(1)
        }
    }
}

// no arguments
LexerTest.run()
ParserTest.run()


func reportTimeSpent(on string: String = "Everything", from: CFAbsoluteTime = startTime) {
    let currentTime = CFAbsoluteTimeGetCurrent()
    let endTime = currentTime - from
    previousTime = currentTime
    print("\(string) took \(round(endTime * 10000)/10000) sec.")
}

func quit(_ code: Int32) -> Never {
    reportTimeSpent()
    exit(code)
}
