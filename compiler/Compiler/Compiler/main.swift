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
var loc = 0

let PrintCursors = CommandLine.arguments.contains("-cursors")
let PrintTime = CommandLine.arguments.contains("-time")
let Silent = CommandLine.arguments.contains("-silent")
let PrintPasses = CommandLine.arguments.contains("--print-passes")
let ColorCode = !CommandLine.arguments.contains("--no-color")

let KeepIR = CommandLine.arguments.contains("-ir")
let KeepGCC = CommandLine.arguments.contains("-gcc")
let RunOutput = CommandLine.arguments.contains("-run")

var outputPath = "output.app"
if CommandLine.arguments.contains("-o"), let i = CommandLine.arguments.firstIndex(of: "-o") {
    guard CommandLine.arguments.count > i + 1 else {
        print("usage: ./compiler -o <filename>")
        quit(1)
    }
    outputPath = CommandLine.arguments[i + 1]
}

if let i = CommandLine.arguments.firstIndex(of: "-file") {
    guard CommandLine.arguments.count > i + 1 else {
        print("usage: ./compiler -file <filename>")
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
        let lexerOutput = try Lexer(code).analyze()
        loc = lexerOutput.linesProcessed
        reportTimeSpent(on: "Lexing", from: previousTime, print: PrintTime)
        
        if CommandLine.arguments.contains("-tokens") {
            print(lexerOutput.tokens.map { String(describing: $0) }.joined(separator: "\n"))
            quit(0)
        }
        
        let result = try Parser(lexerOutput.tokens).parse()
        reportTimeSpent(on: "Parsing", from: previousTime, print: PrintTime)
        
        if CommandLine.arguments.contains("-ast") {
            print(result)
            quit(0)
        }
        
        let ir = IR().generateIR(globalScope: result)

        reportTimeSpent(on: "IR Generation", from: previousTime, print: PrintTime)
        reportTimeSpent(on: "Frontend", from: startTime, print: PrintTime)
        
        do {
            try compileAndSave(ir: ir, output: outputPath)
            
            if RunOutput {
                let output = try runCommand("./\(outputPath)", [])
                reportTimeSpent(on: "Running", from: previousTime, print: PrintTime)
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
            printParserError(pe, code)
            quit(1)
        }
        else {
            print(error.localizedDescription)
            quit(1)
        }
    }
}

func printParserError(_ pe: ParserError, _ code: String) {
    let lineNumber = pe.startCursor.lineNumber
    print("Unexpected parser error @ \(pe.startCursor)")
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
            print("   >    \(String(beforeError))\(String(error).color(.red))\(String(afterError))")
            let startCursor = String(repeating: " ", count: pe.startCursor.character) + "^"
            let endCursor = String(repeating: "^", count: pe.endCursor.character-pe.startCursor.character)
            print("        \(startCursor)\(endCursor)".color(.red))
        }
        else {
            print("Error @ \(pe.startCursor) - \(pe.endCursor)")
            print(">>>>> Unable to point to the error cursor.")
        }

        print("")
        print(pe.message, "\n")
    }
}

// no arguments
LexerTest.run()
ParserTest.run()
