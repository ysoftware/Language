//
//  LoopBreak.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 19.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

// a: Int = 0
// outerLoop: while true {
//     while true {
//         a = a + 1
//         if a > 500 { break outerLoop }
//         if a == 100 { break }
//         if a > 1 { continue }
//         else { printf("Did not continue! a is %d\n\", a) }
//     }
//     printf("Broke out of loop 1, a is %d\n\", a)
// }
// printf("Broke out of loop 2, a is %d\n\", a)
 
let LoopBreakContinueAST = Scope(code: [
    
    VariableDeclaration(id: "global_string_literal_1", expType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Did not continue! a is %d\n\0")),
    VariableDeclaration(id: "global_string_literal_2", expType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Broke out of loop 1, a is %d\n\0")),
    VariableDeclaration(id: "global_string_literal_3", expType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Broke out of loop 2, a is %d\n\0")),
    
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
            
            // a: Int = 0
            VariableDeclaration(id: "global_func_main_variable_a",
                                expType: .int,
                                flags: [], expression: IntLiteral(value: 0)),
            
            // outerLoop: while true {
            WhileLoop(
                userLabel: "outerLoop",
                condition: BoolLiteral(value: true),
                block: Scope(code: [
                    
                    // while true {
                    WhileLoop(
                        userLabel: nil,
                        condition: BoolLiteral(value: true),
                        block: Scope(code: [
                            
                            // a = a + 1
                            VariableAssignment(receiverId: "global_func_main_variable_a", expression:
                                BinaryOperator(name: .add, operatorType: .int, expType: .int, arguments: (
                                    Value(name: "global_func_main_variable_a", expType: .int),
                                    IntLiteral(value: 1)
                                ))
                            ),
                            
                            // if a > 500 { break outerLoop }
                            Condition(
                                condition: BinaryOperator(
                                    name: .signedGreaterThan,
                                    operatorType: .int,
                                    expType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", expType: .int),
                                        IntLiteral(value: 500)
                                )), block: Scope(code: [
                                    Break(userLabel: "outerLoop")
                                ]), elseBlock: .empty),
                            
                            // if a == 100 { break }
                            Condition(
                                condition: BinaryOperator(
                                    name: .equal,
                                    operatorType: .int,
                                    expType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", expType: .int),
                                        IntLiteral(value: 100)
                                )), block: Scope(code: [
                                    Break(userLabel: nil)
                                ]), elseBlock: .empty),
                            
                            // if a > 1 { continue }
                            // else { printf("...", a)
                            Condition(
                                condition: BinaryOperator(
                                    name: .signedGreaterThan,
                                    operatorType: .int,
                                    expType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", expType: .int),
                                        IntLiteral(value: 1)
                                )), block: Scope(code: [
                                    Continue(userLabel: nil)
                                ]), elseBlock: Scope(code: [
                                    
                                    ProcedureCall(
                                        name: "global_func_prinf", expType: .int8, arguments: [
                                            Value(name: "global_string_literal_1", expType: .string),
                                            Value(name: "global_func_main_variable_a", expType: .int32)
                                    ]),
                                ])),
                            
                            
                        ])
                    ),
                    
                    // printf(string2, a)
                    ProcedureCall(
                        name: "global_func_prinf", expType: .int8, arguments: [
                            Value(name: "global_string_literal_2", expType: .string),
                            Value(name: "global_func_main_variable_a", expType: .int32)
                    ]),
                ])
            ),
            
            // printf(string3, a)
            ProcedureCall(
                name: "global_func_prinf", expType: .int8, arguments: [
                    Value(name: "global_string_literal_3", expType: .string),
                    Value(name: "global_func_main_variable_a", expType: .int32)
            ]),
            
            Return(value: IntLiteral(value: 0))
        ]))
])
