//
//  LoopBreak.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 19.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

let LoopBreakContinueAST = Scope(code: [
    
    StringLiteral(id: "global_string_literal_1", value: "Did not continue! a is %d\n\0"),
    StringLiteral(id: "global_string_literal_2", value: "Broke out of the loop, a is %d\n\0"),
    
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
            
            // while true {
            WhileLoop(
                condition: BoolLiteral(value: true),
                block: Scope(code: [
                    
                    VariableAssignment(receiverId: "global_func_main_variable_a", expression:
                        BinaryOperator(name: .add, operatorType: .int, expType: .int, arguments: (
                            Argument(name: "global_func_main_variable_a", expType: .int),
                            IntLiteral(value: 1)
                        ))
                    ),
                    
                    // if a == 100 { break }
                    Condition(
                        condition: BinaryOperator(
                            name: .equal,
                            operatorType: .int,
                            expType: .bool,
                            arguments: (
                                Argument(name: "global_func_main_variable_a", expType: .int),
                                IntLiteral(value: 100)
                        )), block: Scope(code: [
                            Break(userLabel: nil)
                        ]), elseBlock: .empty),
                    
                    // if a > 1 { continue }
                    Condition(
                        condition: BinaryOperator(
                            name: .signedGreaterThan,
                            operatorType: .int,
                            expType: .bool,
                            arguments: (
                                Argument(name: "global_func_main_variable_a", expType: .int),
                                IntLiteral(value: 1)
                        )), block: Scope(code: [
                            Continue(userLabel: nil)
                        ]), elseBlock: Scope(code: [
                            ProcedureCall(
                                name: "global_func_prinf", expType: .int8, arguments: [
                                    Argument(name: "global_string_literal_1", expType: .string),
                                    Argument(name: "global_func_main_variable_a", expType: .int32)
                            ]),
                        ]))
                ])
            ),
            
            // printf(string2, a)
            ProcedureCall(
                name: "global_func_prinf", expType: .int8, arguments: [
                    Argument(name: "global_string_literal_2", expType: .string),
                    Argument(name: "global_func_main_variable_a", expType: .int32)
            ]),
            
            Return(value: IntLiteral(value: 0))
        ]))
])
