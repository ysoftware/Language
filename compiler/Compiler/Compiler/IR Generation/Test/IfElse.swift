//
//  FirstExample.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

func IfElseAST(_ value: Bool) -> Code {
    
    let instruction: Instruction = value ? .sub : .add
    
    return Code([
        
        // "%d\n"
        VariableDeclaration(name: "global_string_literal_1", exprType: .string, flags: .isConstant,
                            expression: StringLiteral(value: "%d\n\0")),
        VariableDeclaration(name: "global_string_literal_2", exprType: .string, flags: .isConstant,
                            expression: StringLiteral(value: "we hit if! %d %d\n\0")),
        VariableDeclaration(name: "global_string_literal_3", exprType: .string, flags: .isConstant,
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
            scope: Code([
                
                // a : Int32 : 3
                VariableDeclaration(name: "global_func_main_variable_a",
                                    exprType: .int,
                                    flags: .isConstant,
                                    expression: IntLiteral(value: 3)),
                
                // b : Int32 = 1
                VariableDeclaration(name: "global_func_main_variable_b",
                                    exprType: .int,
                                    flags: [],
                                    expression: IntLiteral(value: 1)),
                
                // b = a + b
                VariableAssignment(
                    receiverId: "global_func_main_variable_b", expression:
                    BinaryOperator(
                        name: instruction, operatorType: .int, exprType: .int, arguments: (
                            Value(name: "global_func_main_variable_a", exprType: .int),
                            Value(name: "global_func_main_variable_b", exprType: .int)
                    ))
                ),
                
                Condition(
                    condition: BinaryOperator(
                        name: .equal, operatorType: .int, exprType: .int,
                        arguments: (
                            Value(name: "global_func_main_variable_b", exprType: .int),
                            IntLiteral(value: 4)
                        )
                    ), block: Code([
                        
                        ProcedureCall(
                            name: "global_func_prinf", exprType: .int8, arguments: [
                                Value(name: "global_string_literal_2", exprType: .string),
                                Value(name: "global_func_main_variable_a", exprType: .int),
                                IntLiteral(value: 15),
                        ]),
                        
                    ]), elseBlock: Code([
                        
                        ProcedureCall(
                            name: "global_func_prinf", exprType: .int8, arguments: [
                                Value(name: "global_string_literal_3", exprType: .string),
                                Value(name: "global_func_main_variable_a", exprType: .int),
                                Value(name: "global_func_main_variable_b", exprType: .int),
                        ]),
                    ])),
                
                // printf("%d\n", b)
                
                ProcedureCall(
                    name: "global_func_prinf", exprType: .int8, arguments: [
                        Value(name: "global_string_literal_1", exprType: .string),
                        Value(name: "global_func_main_variable_b", exprType: .int),
                ]),
                
                Return(value: IntLiteral(value: 0))
            ]))
    ])
}
