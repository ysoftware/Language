//
//  Utils.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func plural(_ value: Int) -> String { value == 1 ? "" : "s" }

extension String {
    
    func endIndex(offsetBy offset: Int) -> String.Index { index(endIndex, offsetBy: offset) }
    func startIndex(offsetBy offset: Int) -> String.Index { index(startIndex, offsetBy: offset) }
    subscript(index: Int) -> Character { self[startIndex(offsetBy: index)] }
}

extension Ast {
    
    func equals(to ast: Ast?) -> Bool {
        guard let ast = ast else { return false }
        switch (self, ast) {
        case (let l as Code, let r as Code): return l == r
        case (let l as Value, let r as Value): return l == r
        case (let l as ProcedureDeclaration, let r as ProcedureDeclaration): return l == r
        case (let l as StructDeclaration, let r as StructDeclaration): return l == r
        case (let l as VariableDeclaration, let r as VariableDeclaration): return l == r
        case (let l as Assignment, let r as Assignment): return l == r
        case (let l as Condition, let r as Condition): return l == r
        case (let l as WhileLoop, let r as WhileLoop): return l == r
        case (let l as Break, let r as Break): return l == r
        case (let l as Continue, let r as Continue): return l == r
        case (let l as Return, let r as Return): return l == r
        case (let l as BinaryOperator, let r as BinaryOperator): return l == r
        case (let l as UnaryOperator, let r as UnaryOperator): return l == r
        case (let l as ProcedureCall, let r as ProcedureCall): return l == r
        case (let l as StringLiteral, let r as StringLiteral): return l == r
        case (let l as IntLiteral, let r as IntLiteral): return l == r
        case (let l as FloatLiteral, let r as FloatLiteral): return l == r
        case (is VoidLiteral, is VoidLiteral): return true
        default: return false
        }
    }
}

func compileAndSave(ir: String, output: String) throws {
    let urlIR = URL(fileURLWithPath: "\(output).ll")
    let urlO = URL(fileURLWithPath: "\(output).o")
    
    try ir.write(to: urlIR, atomically: true, encoding: .utf8)
    
    let llvmResult = try runCommand("/usr/local/opt/llvm/bin/llc", ["-filetype=obj", urlIR.path])
    outputCommand("LLVM", llvmResult)
    reportTimeSpent(on: "LLVM", from: previousTime, print: PrintTime)
    
    let gccResult = try runCommand("/usr/bin/gcc", ["-o", "\(output)", urlO.path])
    outputCommand("GCC", gccResult)
    reportTimeSpent(on: "GCC", from: previousTime, print: PrintTime)
    
    if !KeepIR {
        try FileManager.default.removeItem(atPath: urlIR.path)
    }
    if !KeepGCC {
        try FileManager.default.removeItem(atPath: urlO.path)
    }
}

func outputCommand(_ app: String, _ result: (status: Int32, output: String, error: String)) {
    if !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        print(result.output)
    }
    if result.status != 0 {
        print("\(app): Ended with code: \(result.status).")
        print(result.error)
        quit(1)
    }
}

@discardableResult
func runCommand(_ app: String, _ arguments: [String]) throws -> (status: Int32, output: String, error: String) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: app)
    task.arguments = arguments
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    
    try task.run()
    task.waitUntilExit()
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let error = String(decoding: errorData, as: UTF8.self)
    return (task.terminationStatus, output, error)
}

enum BashColor: Int {
    case black = 30
    case red = 31
    case green = 32
    case yellow = 33
    case blue = 34
    case magenta = 35
    case cyan = 36
    case lightGray = 37
    case darkGray = 90
    case lightRed = 91
    case lightGreen = 92
    case lightYellow = 93
    case lightBlue = 94
    case lightMagenta = 95
    case lightCyan = 96
    case white = 97
}

extension String {
    
    func color(_ color: BashColor) -> String {
        if !ColorCode { return self }
        return "\u{001B}[0;\(color.rawValue)m\(self)\u{001B}[0;0m"
    }
    
    var reescaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}


func reportTimeSpent(on string: String = "Everything", from: CFAbsoluteTime = startTime, print: Bool) {
    guard !Silent else { return }
    let currentTime = CFAbsoluteTimeGetCurrent()
    let endTime = currentTime - from
    previousTime = currentTime
    var output = "\(string) took \(round(endTime * 10000)/10000) sec."

    if loc != 0 && (string == "Lexing") {
        let klocps = Float(loc) / Float(previousTime - startTime) / 1000
        output += " \(loc) lines (\(klocps) kloc/s)"
    }
    if print { Swift.print(output) }
}

func quit(_ code: Int32) -> Never {
    reportTimeSpent(print: true)
    exit(code)
}

func stringToAST(_ string: String) -> Code? {
    do {
        let lexerOutput = try Lexer(string).analyze()
        let code = try Parser(lexerOutput.tokens).parse()
        return code
    }
    catch {
        return nil
    }
}
