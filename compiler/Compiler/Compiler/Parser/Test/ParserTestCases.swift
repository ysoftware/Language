//
//  ParserTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension ParserTest {
    
    func testVariableDeclaration() {
        let code = """
func main() { a : String; b := 1; c :: "hello"; d : Int = 1;
e : Bool : true; f := 1.0; g :: false; h :: 5_000_000_000_000; }
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Code([
            ProcedureDeclaration(
                id: "__global_func_main", name: "main", arguments: [],
                returnType: .void, flags: [], scope: Code([
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
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "__global_func_print1", name: "print1", arguments: [.string, .int32],
                returnType: .void, flags: [.isVarargs, .isForeign], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print2", name: "print2", arguments: [.string, .int32],
                returnType: .void, flags: [], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print3", name: "print3", arguments: [],
                returnType: .void, flags: [], scope: Code([
    VariableDeclaration(name: "x", exprType: .int, flags: [.isConstant], expression: IntLiteral(value: 1))
                ])),
        ]))
    }
    
    func testStructDeclaration() {
        // @Todo: finish this test
//        let code = "1struct c { a: String; b :: 1; }" // @Lexer @Todo: this passes (with 1 at the start)
        let code = "x := 1.0; struct A { a: String; b :: 1; c := b; d := x; }"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
    VariableDeclaration(name: "x", exprType: .float, flags: [], expression: FloatLiteral(value: 1)),
            StructDeclaration(name: "A", members: [
    VariableDeclaration(name: "a", exprType: .string, flags: [], expression: nil),
    VariableDeclaration(name: "b", exprType: .int, flags: .isConstant, expression: IntLiteral(value: 1)),
    VariableDeclaration(name: "c", exprType: .int, flags: [], expression: Value(name: "b", exprType: .int)),
    VariableDeclaration(name: "d", exprType: .float, flags: [], expression: Value(name: "x", exprType: .float)),
            ])
        ]))
    }
    
    func testTypeInferenceGlobalProc() { /// types of a and b are inferred from the known procedure declarations (1st pass)
        let code = """
func getInt() -> Int { return 1; }
func getString() -> String { return "hello"; }
struct Value { a := getInt(); b := getString(); }
"""
        
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "__global_func_getInt", name: "getInt", arguments: [],
                returnType: .int, flags: [], scope: Code([Return(value: IntLiteral(value: 1))])),
            ProcedureDeclaration(
                id: "__global_func_getString", name: "getString", arguments: [],
                returnType: .string, flags: [], scope: Code([
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
    
    func testTypeInference() {
        let code = "c:= 1; func main() { a := c; b := a; }"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Code([
                VariableDeclaration(name: "c", exprType: .int, flags: [], expression: IntLiteral(value: 1)),
                ProcedureDeclaration(
                    id: "__global_func_main", name: "main", arguments: [],
                    returnType: .void, flags: [], scope: Code([
        VariableDeclaration(name: "a", exprType: .int, flags: [], expression: Value(name: "c", exprType: .int)),
        VariableDeclaration(name: "b", exprType: .int, flags: [], expression: Value(name: "a", exprType: .int)),
                    ])),
            ]))
    }
    
    func testTypeInference2() {
        // @Todo this test should fail when 2nd pass type inference is implemented
        // this just stops at the type being unresolved
        let code = "func main() { if (true) { a := 1; if (false) { b := a; }} else { c := a; }}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Code([
                ProcedureDeclaration(
                    id: "__global_func_main", name: "main", arguments: [],
                    returnType: .void, flags: [], scope: Code([
                        Condition(condition: BoolLiteral(value: true), block: Code([
                            VariableDeclaration(name: "a", exprType: .int, flags: [], expression:
                                IntLiteral(value: 1)),
                            Condition(condition: BoolLiteral(value: false), block: Code([
                                VariableDeclaration(name: "b", exprType: .int, flags: [], expression:
                                    Value(name: "a", exprType: .int)),
                            ]), elseBlock: .empty)
                        ]), elseBlock: Code([
                            VariableDeclaration(name: "c", exprType: .unresolved(name: nil), flags: [], expression:
                                Value(name: "a", exprType: .unresolved(name: nil))),
                        ])),
                    ])),
            ]))
    }
    
    func testWhileLoop() {
        let code = "func main() { while (true) { }}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()

        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "__global_func_main", name: "main", arguments: [],
                returnType: .void, flags: [], scope: Code([
                    WhileLoop(userLabel: nil, condition: BoolLiteral(value: true), block: .empty)
                ])),
        ]))
    }
    
    func testWhileLoopBreak() {
        let code = "func main() { loop: while (true) { loop1: while (true) { break loop; }}}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()

        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "__global_func_main", name: "main", arguments: [],
                returnType: .void, flags: [], scope: Code([
                    WhileLoop(userLabel: "loop", condition: BoolLiteral(value: true), block: Code([
                        WhileLoop(userLabel: "loop1", condition: BoolLiteral(value: true), block: Code([
                            Break(userLabel: "loop")
                        ]))
                    ]))
                ])),
        ]))
    }
}
