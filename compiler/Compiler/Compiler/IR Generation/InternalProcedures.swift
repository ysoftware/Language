//
//  InternalProcedures.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 12.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let internalProcedures = [
    "int8PointerToInt32", // func int8PointerToInt32(pointer: Int8*) -> Int32 #foreign;
    "int32AsInt8Pointer"  // func int32AsInt8Pointer(address: Int32) -> Int8* #foreign;
]

internal extension IR {
    
    // @Todo: refactor into IRGenError
    func doInternalProcedure(_ call: ProcedureCall, ident: Int) -> (code: String?, value: String) {
        let identation = string(for: ident)
        
        if call.name == "int8PointerToInt32" {
            
            guard call.arguments.count == 1 else {
                report("\(call.name) expects exactly 1 argument", call.startCursor, call.endCursor)
            }
            
            let arg = call.arguments[0]
            guard arg.exprType.equals(to: .pointer(.int8)) else {
                report("\(call.name): Pointer expected, got \(arg.exprType.typeName) instead.",
                    arg.startCursor, arg.endCursor)
            }
            
           var code = ""
            let (load, val) = getExpressionResult(arg, ident: ident)
            load.map { code += "\(identation)\($0)\n" }
            
            let counter = count()
            let value = "%\(counter)"
            code += "\n\(identation)\(value) = ptrtoint \(matchType(arg.exprType)) \(val) to \(matchType(.int32))"
            
            return (code, value)
        }
        if call.name == "int32AsInt8Pointer" {
            
            // @Todo: this doesn't seem to work: Segmentation fault: 11
            
            guard call.arguments.count == 1 else {
                report("\(call.name) expects exactly 1 argument", call.startCursor, call.endCursor)
            }
            
            let arg = call.arguments[0]
            guard arg.exprType.equals(to: .int32) else {
                report("\(call.name): Int32 expected, got \(arg.exprType.typeName) instead.",
                    arg.startCursor, arg.endCursor)
            }
            
           var code = ""
            let (load, val) = getExpressionResult(arg, ident: ident)
            load.map { code += "\(identation)\($0)\n" }
            
            let counter = count()
            let value = "%\(counter)"
            code += "\n\(identation)\(value) = inttoptr \(matchType(arg.exprType)) \(val) to \(matchType(.pointer(.int8)))"
            
            return (code, value)
        }
        report("Internal procedure '\(call.name)' is not implemented yet.")
    }
}
