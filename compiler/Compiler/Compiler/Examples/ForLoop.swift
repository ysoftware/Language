//
//  ForLoop.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

let ForLoop = Scope(code: [
    
    StringLiteral(id: "global_string_literal_1", value: "a == %d\n\0"),
    StringLiteral(id: "global_string_literal_2", value: "Left the loop, a == %d\n\0"),
    
    // func printf(_ format: String, _ arguments: Int32...) -> Int32 #foreign
    ProcedureDeclaration(
        id: "global_func_prinf", name: "printf",
        arguments: [.string, .int32], returnType: .int32,
        flags: [.isForeign, .isVarargs], scope: .empty),
    
    // func main() -> Int32 {
    ProcedureDeclaration(
        id: "global_func_main",
        name: "main",
        arguments: [],
        returnType: .int32,
        flags: [],
        scope: Scope(code: [
            
            // a: Int = 10
            VariableDeclaration(id: "global_func_main_variable_a",
                                type: .int,
                                flags: [], expression: IntLiteral(value: 10)),
            
            // while a != 0 {
            WhileLoop(
                condition: BinaryOperator(
                    name: .notEqual, operatorType: .int, type: .bool,
                    arguments: (
                        Argument(name: "global_func_main_variable_a", type: .int),
                        IntLiteral(value: 0)
                )),
                block: Scope(code: [
                    
                    // printf(string1, a)
                    ProcedureCall(
                        name: "global_func_prinf", type: .int8, arguments: [
                            Argument(name: "global_string_literal_1", type: .string),
                            Argument(name: "global_func_main_variable_a", type: .int)
                    ]),
                    
                    VariableAssignment(receiverId: "global_func_main_variable_a", expression:
                        BinaryOperator(name: .sub, operatorType: .int, type: .int, arguments: (
                            Argument(name: "global_func_main_variable_a", type: .int),
                            IntLiteral(value: 1)
                        ))
                    )
                ])
            ),
            
            // printf(string2, a)
            ProcedureCall(
                name: "global_func_prinf", type: .int8, arguments: [
                    Argument(name: "global_string_literal_2", type: .string),
                    Argument(name: "global_func_main_variable_a", type: .int32)
            ]),
            
            Return(value: IntLiteral(value: 0))
        ]))
])
