//
//  ForLoop.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

let WhileLoopAST = Scope(code: [
    
    VariableDeclaration(name: "global_string_literal_1", expType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "a == %d\n\0")),
    VariableDeclaration(name: "global_string_literal_2", expType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Left the loop, a == %d\n\0")),
    
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
            VariableDeclaration(name: "global_func_main_variable_a",
                                expType: .int,
                                flags: [], expression: IntLiteral(value: 10)),
            
            // while a != 0 {
            WhileLoop(
                userLabel: nil,
                condition: BinaryOperator(
                    name: .notEqual, operatorType: .int, expType: .bool,
                    arguments: (
                        Value(name: "global_func_main_variable_a", expType: .int),
                        IntLiteral(value: 0)
                )),
                block: Scope(code: [
                    
                    // printf(string1, a)
                    ProcedureCall(
                        name: "global_func_prinf", expType: .int8, arguments: [
                            Value(name: "global_string_literal_1", expType: .string),
                            Value(name: "global_func_main_variable_a", expType: .int)
                    ]),
                    
                    VariableAssignment(receiverId: "global_func_main_variable_a", expression:
                        BinaryOperator(name: .sub, operatorType: .int, expType: .int, arguments: (
                            Value(name: "global_func_main_variable_a", expType: .int),
                            IntLiteral(value: 1)
                        ))
                    )
                ])
            ),
            
            // printf(string2, a)
            ProcedureCall(
                name: "global_func_prinf", expType: .int8, arguments: [
                    Value(name: "global_string_literal_2", expType: .string),
                    Value(name: "global_func_main_variable_a", expType: .int32)
            ]),
            
            Return(value: IntLiteral(value: 0))
        ]))
])
