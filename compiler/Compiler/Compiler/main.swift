//
//  main.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let ast = Scope(code: [
    
    // "%d\n"
    
    StringLiteral(id: "global_string_literal_1", value: "%d\n\0"),
    
    // func printf(_ format: String, _ arguments: Int32...) -> Int32 #foreign
    
    ProcedureDeclaration(
        id: "global_func_prinf", name: "printf",
        arguments: [.string, .int32], returnType: .int32,
        flags: [.isForeign, .isVarargs], code: .empty),
    
    // func main() -> Int32 {
    
    ProcedureDeclaration(
        id: "global_func_main",
        name: "main",
        arguments: [],
        returnType: .int32,
        flags: [],
        code: Scope(code: [
            
            // a : Int32 : 3
            
            VariableDeclaration(id: "global_func_main_variable_a",
                                type: .int32,
                                flags: .isConstant,
                                expression: IntLiteral(id: nil, value: 3)),
            // b : Int32 = 1
            
            VariableDeclaration(id: "global_func_main_variable_b",
                                type: .int32,
                                flags: [],
                                expression: IntLiteral(id: nil, value: 1)),
            
            // b = a + b
            
            VariableAssignment(
                receiverId: "global_func_main_variable_b", expression:
                BinaryOperator(
                    name: "add", type: .int32, arguments: (
                        Argument(name: "global_func_main_variable_a", type: .int32),
                        Argument(name: "global_func_main_variable_b", type: .int32)
                    ))
            ),
            
            // printf("%d\n", b)
            
            ProcedureCall(
                name: "global_func_prinf", type: .int8, arguments: [
                    Argument(name: "global_string_literal_1", type: .string),
                    Argument(name: "global_func_main_variable_b", type: .int32),
            ]),
            
            Return(value: IntLiteral(id: nil, value: 0))
    ]))
])

let ir = IR.generateIR(globalScope: ast)

print("Program output:\n")
print(ir)
print("\n")
