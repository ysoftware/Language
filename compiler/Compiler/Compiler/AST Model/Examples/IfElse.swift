//
//  FirstExample.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

func IfElseAST(_ value: Bool) -> Scope {
    
    let instruction: Operator = value ? .sub : .add
    
    return Scope(code: [
        
        // "%d\n"
        VariableDeclaration(id: "global_string_literal_1", expType: .string, flags: .isConstant,
                            expression: StringLiteral(value: "%d\n\0")),
        VariableDeclaration(id: "global_string_literal_2", expType: .string, flags: .isConstant,
                            expression: StringLiteral(value: "we hit if! %d %d\n\0")),
        VariableDeclaration(id: "global_string_literal_3", expType: .string, flags: .isConstant,
                            expression: StringLiteral(value: "we hit else %d %d\n\0")),
        
        // func printf(_ format: String, _ arguments: Int32...) -> Int32 #foreign
        
        ProcedureDeclaration(
            id: "global_func_prinf", name: "printf",
            arguments: [.string, .int], returnType: .int,
            flags: [.isForeign, .isVarargs], scope: .empty),
        
        // func main() -> Int32 {
        
        ProcedureDeclaration(
            id: "global_func_main",
            name: "main",
            arguments: [],
            returnType: .int,
            flags: [],
            scope: Scope(code: [
                
                // a : Int32 : 3
                VariableDeclaration(id: "global_func_main_variable_a",
                                    expType: .int,
                                    flags: .isConstant,
                                    expression: IntLiteral(value: 3)),
                
                // b : Int32 = 1
                VariableDeclaration(id: "global_func_main_variable_b",
                                    expType: .int,
                                    flags: [],
                                    expression: IntLiteral(value: 1)),
                
                // b = a + b
                VariableAssignment(
                    receiverId: "global_func_main_variable_b", expression:
                    BinaryOperator(
                        name: instruction, operatorType: .int, expType: .int, arguments: (
                            Argument(name: "global_func_main_variable_a", expType: .int),
                            Argument(name: "global_func_main_variable_b", expType: .int)
                    ))
                ),
                
                Condition(
                    condition: BinaryOperator(
                        name: .equal, operatorType: .int, expType: .int,
                        arguments: (
                            Argument(name: "global_func_main_variable_b", expType: .int),
                            IntLiteral(value: 4)
                        )
                    ), block: Scope(code: [
                        
                        // @Todo: can't pass literal as argument
                        
                        ProcedureCall(
                            name: "global_func_prinf", expType: .int8, arguments: [
                                Argument(name: "global_string_literal_2", expType: .string),
                                Argument(name: "global_func_main_variable_a", expType: .int),
                                Argument(name: "global_func_main_variable_b", expType: .int),
                        ]),
                        
                    ]), elseBlock: Scope(code: [
                        
                        ProcedureCall(
                            name: "global_func_prinf", expType: .int8, arguments: [
                                Argument(name: "global_string_literal_3", expType: .string),
                                Argument(name: "global_func_main_variable_a", expType: .int),
                                Argument(name: "global_func_main_variable_b", expType: .int),
                        ]),
                    ])),
                
                // printf("%d\n", b)
                
                ProcedureCall(
                    name: "global_func_prinf", expType: .int8, arguments: [
                        Argument(name: "global_string_literal_1", expType: .string),
                        Argument(name: "global_func_main_variable_b", expType: .int),
                ]),
                
                Return(value: IntLiteral(value: 0))
            ]))
    ])
}
