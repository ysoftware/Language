//
//  InternalProcedures.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 12.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let internalProcedures: [ProcedureDeclaration] = [
    "func pointerToInt(pointer: Any*) -> Int32 #foreign;"
].compactMap(stringToAST).compactMap { $0.statements.first as? ProcedureDeclaration }

internal extension IR {
    
    // @Todo: refactor into IRGenError
    func doInternalProcedure(_ call: ProcedureCall) -> (code: String?, value: String) {
        
        if call.name == "pointerToInt" {
            guard call.arguments.count == 1 else {
                report("\(call.name) expects exactly 1 argument", call.range)
            }
            
            let arg = call.arguments[0]
            guard arg.exprType is PointerType else {
                report("\(call.name): Pointer expected, got \(arg.exprType.typeName) instead.", arg.range)
            }
            
           var code = ""
            let (load, val) = getExpressionResult(arg)
            load.map { code += "\($0)\n" }
            
            let counter = count()
            let value = "%\(counter)"
            code += "\n\(value) = ptrtoint \(matchType(arg.exprType)) \(val) to \(matchType(int32))"
            
            return (code, value)
        }
        report("Internal procedure '\(call.name)' is not implemented yet.")
    }
}
