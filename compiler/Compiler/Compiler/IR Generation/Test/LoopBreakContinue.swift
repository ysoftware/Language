//
//  LoopBreak.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 19.05.2020.
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
 
let LoopBreakContinueAST = Code([
    
    VariableDeclaration(name: "global_string_literal_1", exprType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Did not continue! a is %d\n\0")),
    VariableDeclaration(name: "global_string_literal_2", exprType: .string, flags: .isConstant,
                        expression: StringLiteral(value: "Broke out of loop 1, a is %d\n\0")),
    VariableDeclaration(name: "global_string_literal_3", exprType: .string, flags: .isConstant,
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
        scope: Code([
            
            // a: Int = 0
            VariableDeclaration(name: "global_func_main_variable_a",
                                exprType: .int,
                                flags: [], expression: IntLiteral(value: 0)),
            
            // outerLoop: while true {
            WhileLoop(
                userLabel: "outerLoop",
                condition: BoolLiteral(value: true),
                block: Code([
                    
                    // while true {
                    WhileLoop(
                        userLabel: nil,
                        condition: BoolLiteral(value: true),
                        block: Code([
                            
                            // a = a + 1
                            VariableAssignment(receiverId: "global_func_main_variable_a", expression:
                                BinaryOperator(name: "+", operatorType: .int, exprType: .int, arguments: (
                                    Value(name: "global_func_main_variable_a", exprType: .int),
                                    IntLiteral(value: 1)
                                ))
                            ),
                            
                            // if a > 500 { break outerLoop }
                            Condition(
                                condition: BinaryOperator(
                                    name: ">",
                                    operatorType: .int,
                                    exprType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", exprType: .int),
                                        IntLiteral(value: 500)
                                )), block: Code([
                                    Break(userLabel: "outerLoop")
                                ]), elseBlock: .empty),
                            
                            // if a == 100 { break }
                            Condition(
                                condition: BinaryOperator(
                                    name: "==",
                                    operatorType: .int,
                                    exprType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", exprType: .int),
                                        IntLiteral(value: 100)
                                )), block: Code([
                                    Break(userLabel: nil)
                                ]), elseBlock: .empty),
                            
                            // if a > 1 { continue }
                            // else { printf("...", a)
                            Condition(
                                condition: BinaryOperator(
                                    name: ">",
                                    operatorType: .int,
                                    exprType: .bool,
                                    arguments: (
                                        Value(name: "global_func_main_variable_a", exprType: .int),
                                        IntLiteral(value: 1)
                                )), block: Code([
                                    Continue(userLabel: nil)
                                ]), elseBlock: Code([
                                    
                                    ProcedureCall(
                                        name: "global_func_prinf", exprType: .int8, arguments: [
                                            Value(name: "global_string_literal_1", exprType: .string),
                                            Value(name: "global_func_main_variable_a", exprType: .int32)
                                    ]),
                                ])),
                            
                            
                        ])
                    ),
                    
                    // printf(string2, a)
                    ProcedureCall(
                        name: "global_func_prinf", exprType: .int8, arguments: [
                            Value(name: "global_string_literal_2", exprType: .string),
                            Value(name: "global_func_main_variable_a", exprType: .int32)
                    ]),
                ])
            ),
            
            // printf(string3, a)
            ProcedureCall(
                name: "global_func_prinf", exprType: .int8, arguments: [
                    Value(name: "global_string_literal_3", exprType: .string),
                    Value(name: "global_func_main_variable_a", exprType: .int32)
            ]),
            
            Return(value: IntLiteral(value: 0))
        ]))
])
