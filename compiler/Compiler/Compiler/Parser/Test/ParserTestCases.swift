//
//  ParserTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension ParserTest {
    
func main() {
    a := 1;
    b := a;
}
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Scope(code: [
                ProcedureDeclaration(
                    id: "__global_func_main", name: "main", arguments: [],
                    returnType: .void, flags: [], scope: Scope(code: [
            VariableDeclaration(name: "a", exprType: .int, flags: [], expression: IntLiteral(value: 1)),
            VariableDeclaration(name: "b", exprType: .int, flags: [], expression:
                Value(name: "a", exprType: .int)),
                    ])),
            ]))
    }
    
    func testVariableDeclaration() {
        let code = """
func main() {
    a : String;
    b := 1;
    c :: "hello";
    d : Int = 1;
    e : Bool : true;
    f := 1.0;
    g :: false;
    h :: 5_000_000_000_000; // @Todo: this should result in Int64
}
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Scope(code: [
            ProcedureDeclaration(
                id: "__global_func_main", name: "main", arguments: [],
                returnType: .void, flags: [], scope: Scope(code: [
    VariableDeclaration(name: "a", exprType: .string, flags: [], expression: nil),
    VariableDeclaration(name: "b", exprType: .int, flags: [], expression: IntLiteral(value: 1)),
    VariableDeclaration(name: "c", exprType: .string, flags: [.isConstant], expression: StringLiteral(value: "hello")),
    VariableDeclaration(name: "d", exprType: .int, flags: [], expression: IntLiteral(value: 1)),
    VariableDeclaration(name: "e", exprType: .bool, flags: [.isConstant], expression: BoolLiteral(value: true)),
    VariableDeclaration(name: "f", exprType: .float, flags: [], expression: FloatLiteral(value: 1)),
    VariableDeclaration(name: "g", exprType: .bool, flags: [.isConstant], expression: BoolLiteral(value: false)),
    VariableDeclaration(name: "h", exprType: .int64, flags: [.isConstant], expression: IntLiteral(value: 5_000_000_000_000)),
                ])),
        ]))
    }
    
    func testFunctionDeclaration() {
        let code = """
func print1(format: String, arguments: Int32, ...) #foreign;
func print2(format: String, arguments: Int32) {  }
func print3() { x :: 1; }
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Scope(code: [
            ProcedureDeclaration(
                id: "__global_func_print1", name: "print1", arguments: [.string, .int32],
                returnType: .void, flags: [.isVarargs, .isForeign], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print2", name: "print2", arguments: [.string, .int32],
                returnType: .void, flags: [], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print3", name: "print3", arguments: [],
                returnType: .void, flags: [], scope: Scope(code: [
                    VariableDeclaration(name: "x", exprType: .int, flags: [.isConstant], expression: IntLiteral(value: 1))
                ])),
        ]))
    }
    
    func testStructDeclaration() {
        // @Todo: finish this test
        let code = "struct c { a: String; b :: 1; }"
        //        let code = "1struct c { a: String; b :: 1; }" // @Todo: this passes (with 1 at the start)
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Scope(code: [
            StructDeclaration(name: "c", members: [
        VariableDeclaration(name: "a", exprType: .string, flags: [], expression: nil),
        VariableDeclaration(name: "b", exprType: .int, flags: .isConstant, expression: IntLiteral(value: 1))
            ])
        ]))
    }
    
    func testTypeInferenceGlobal() { /// types of a and b are inferred from the known procedure declarations (1st pass)
        let code = """
func getInt() -> Int { return 1; }
func getString() -> String { return "hello"; }
struct Value { a := getInt(); b := getString(); }
"""
        
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Scope(code: [
            ProcedureDeclaration(
                id: "__global_func_getInt", name: "getInt", arguments: [],
                returnType: .int, flags: [], scope: Scope(code: [Return(value: IntLiteral(value: 1))])),
            ProcedureDeclaration(
                id: "__global_func_getString", name: "getString", arguments: [],
                returnType: .string, flags: [], scope: Scope(code: [
                    Return(value: StringLiteral(value: "hello"))
                ])),
            StructDeclaration(name: "Value", members: [
                VariableDeclaration(name: "a", exprType: .int, flags: [], expression:
                    ProcedureCall(name: "getInt", exprType: .int, arguments: [])),
                VariableDeclaration(name: "b", exprType: .string, flags: [], expression:
                    ProcedureCall(name: "getString", exprType: .string, arguments: []))
            ])
        ]))
    }
}
