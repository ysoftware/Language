//
//  ParserTestCases.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 23.05.2020.
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
                main([
    VariableDeclaration(name: "a", exprType: .string, flags: [], expression: nil),
    VariableDeclaration(name: "b", exprType: .int, flags: [], expression: int(1)),
    VariableDeclaration(name: "c", exprType: .string, flags: [.isConstant], expression: string("hello")),
    VariableDeclaration(name: "d", exprType: .int, flags: [], expression: int(1)),
    VariableDeclaration(name: "e", exprType: .bool, flags: [.isConstant], expression: bool(true)),
    VariableDeclaration(name: "f", exprType: .float, flags: [], expression: float(1)),
    VariableDeclaration(name: "g", exprType: .bool, flags: [.isConstant], expression: bool(false)),
    VariableDeclaration(name: "h", exprType: .int64, flags: [.isConstant], expression: int(5_000_000_000_000)),
                ])
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
    VariableDeclaration(name: "x", exprType: .int, flags: [.isConstant], expression: int(1))
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
    VariableDeclaration(name: "x", exprType: .float, flags: [], expression: float(1)),
            StructDeclaration(name: "A", members: [
    VariableDeclaration(name: "a", exprType: .string, flags: [], expression: nil),
    VariableDeclaration(name: "b", exprType: .int, flags: .isConstant, expression: int(1)),
    VariableDeclaration(name: "c", exprType: .int, flags: [], expression: Value(name: "b", exprType: .int)),
    VariableDeclaration(name: "d", exprType: .float, flags: [], expression: Value(name: "x", exprType: .float)),
            ])
        ]))
    }
    
    func testTypeInferenceGlobalProc() {
        // types of a and b are inferred from the known procedure declarations (1st pass)
        
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
                returnType: .int, flags: [], scope: Code([Return(value: int(1))])),
            ProcedureDeclaration(
                id: "__global_func_getString", name: "getString", arguments: [],
                returnType: .string, flags: [], scope: Code([
                    Return(value: string("hello"))
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
                VariableDeclaration(name: "c", exprType: .int, flags: [], expression: int(1)),
                main([
    VariableDeclaration(name: "a", exprType: .int, flags: [], expression: Value(name: "c", exprType: .int)),
    VariableDeclaration(name: "b", exprType: .int, flags: [], expression: Value(name: "a", exprType: .int)),
                ])
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
                main([
                    Condition(condition: bool(true), block: Code([
                        VariableDeclaration(name: "a", exprType: .int, flags: [], expression:
                            int(1)),
                        Condition(condition: bool(false), block: Code([
                            VariableDeclaration(name: "b", exprType: .int, flags: [], expression:
                                Value(name: "a", exprType: .int)),
                        ]), elseBlock: .empty)
                    ]), elseBlock: Code([
                        VariableDeclaration(name: "c", exprType: .unresolved(name: nil), flags: [], expression:
                            Value(name: "a", exprType: .unresolved(name: nil))),
                    ])),
                ])
            ]))
    }
    
    func testWhileLoop() {
        let code = "func main() { while (true) { }}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()

        printResultCase(code, result, Code([
            main([ WhileLoop(userLabel: nil, condition: bool(true), block: .empty) ])
        ]))
    }
    
    func testWhileLoopBreak() {
        // @Todo: you can pass string literal with no error as while condition
        let code = "func main() { loop: while (true) { loop1: while (true) { break loop; }}}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
            main([
                WhileLoop(userLabel: "loop", condition: bool(true), block: Code([
                    WhileLoop(userLabel: "loop1", condition: bool(true), block: Code([
                        Break(userLabel: "loop")
                    ]))
                ]))
            ])
        ]))
    }
    
    func testWhileLoopContinue() {
        let code = "func main() { loop: while (true) { loop1: while (true) { continue loop; }}}"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()

        printResultCase(code, result, Code([
            main([
                WhileLoop(userLabel: "loop", condition: bool(true), block: Code([
                    WhileLoop(userLabel: "loop1", condition: bool(true), block: Code([
                        Continue(userLabel: "loop")
                    ]))
                ]))
            ])
        ]))
    }
    
    func testUnaryOperators() {
        let code = "func main() { a := 1; b := -a; }"
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
            main([
                VariableDeclaration(name: "a", exprType: .int, flags: [], expression: int(1)),
                VariableDeclaration(name: "b", exprType: .int, flags: [], expression:
                    UnaryOperator(name: "-", operatorType: .int, exprType: .int, argument:
                        Value(name: "a", exprType: .int)))
            ])
        ]))
    }
    
    func testPrecedence() {
        let code = "func main() { a := (1 + 3) * (1 + 7 / -(5 + 3)) % 100 - 0.5; }"
        // 5 + 3
        // -(5 + 3)
        // 7 / -(5 + 3)
        // 1 + (7 / -(5 + 3))
        // ---
        // 1 + 3
        // (1 + 3) * (1 + (7 / -(5 + 3)))
        // ---
        // (1 + 3) * (1 + (7 / -(5 + 3))) % 100
        // ((1 + 3) * (1 + (7 / -(5 + 3))) % 100) - 0.5   = 0
        
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
            main([
                VariableDeclaration(name: "a", exprType: .int, flags: [], expression:
                    int(1))
                
                
            ])
        ]))
    }
    
    func testBinaryOperators() {
        let code = "func main() { a := 1 + 3 * 2; b := a - 2; c := a * b; }"
        
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Code([
            main([
                VariableDeclaration(name: "a", exprType: .int, flags: [], expression:
                    BinaryOperator(name: "+", operatorType: .int, exprType: .int, arguments: (
                        int(1),
                        BinaryOperator(name: "*", operatorType: .int, exprType: .int, arguments: (
                            int(3), int(2))))
                )),
                VariableDeclaration(name: "b", exprType: .int, flags: [], expression:
                    BinaryOperator(name: "-", operatorType: .int, exprType: .int, arguments: (
                        Value(name: "a", exprType: .int), int(2))
                )),
                VariableDeclaration(name: "c", exprType: .int, flags: [], expression:
                    BinaryOperator(name: "*", operatorType: .int, exprType: .int, arguments: (
                        Value(name: "a", exprType: .int), Value(name: "b", exprType: .int)
                    )))
            ])
        ]))
    }
}
