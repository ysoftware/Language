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

extension Result where Failure == ParserError {
    
    func assign(_ pointer: inout Success?) -> ParserError? {
        switch self {
        case .success(let value): pointer = value; return nil
        case .failure(let error): return error
        }
    }
    
    func assign(_ pointer: inout Success) -> ParserError? {
        switch self {
        case .success(let value): pointer = value; return nil
        case .failure(let error): return error
        }
    }
    
    func then(_ block: (Success)->Void) -> ParserError? {
        switch self {
        case .success(let value): block(value); return nil
        case .failure(let error): return error
        }
    }
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
        case (let l as VariableAssignment, let r as VariableAssignment): return l == r
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

func compileAndSave(ir: String, output: String = "output") throws {
    let path = FileManager.default.currentDirectoryPath
    
    let urlIR = URL(fileURLWithPath: path).appendingPathComponent("\(output).ll")
    let urlO = URL(fileURLWithPath: path).appendingPathComponent("\(output).o")
    
    try ir.write(to: urlIR, atomically: true, encoding: .utf8)
    
    let llvmResult = try runCommand("/usr/local/opt/llvm/bin/llc", ["-filetype=obj", urlIR.path])
    outputCommand("LLVM", llvmResult)
    let gccResult = try runCommand("/usr/bin/gcc", ["-o", "\(output).app", urlO.path])
    outputCommand("GCC", gccResult)
    
//    try FileManager.default.removeItem(atPath: urlIR.path)
//    try FileManager.default.removeItem(atPath: urlO.path)
}

func outputCommand(_ app: String, _ result: (status: Int32, output: String, error: String)) {
    if !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        print(result.output)
    }
    if result.status != 0 {
        print("\(app): Ended with code: \(result.status).")
        print(result.error)
        exit(1)
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
