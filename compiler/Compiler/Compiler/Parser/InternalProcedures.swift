//
//  InternalProcedures.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 12.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let internalProcedures: [String: ProcedureDeclaration] = [
    
    "int8PointerToInt32":
        ProcedureDeclaration(id: "int8PointerToInt32", name: "int8PointerToInt32",
                             arguments: [Value(name: "pointer", exprType: .pointer(.int8))],
                             returnType: .int32, flags: .isForeign, scope: .empty),
    
    "int32AsInt8Pointer":
        ProcedureDeclaration(id: "int32AsInt8Pointer", name: "int32AsInt8Pointer",
                             arguments: [Value(name: "pointer", exprType: .int32)],
                             returnType: .pointer(.int8), flags: .isForeign, scope: .empty)
]
