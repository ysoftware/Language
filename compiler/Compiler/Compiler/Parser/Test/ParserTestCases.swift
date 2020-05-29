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
func main() {
    a : String;
    b := 1;
    c :: "hello";
    // d : Int = 1; // @Todo: this fails: Type supplied does not match the type of expression
    // e : Bool : true; // @Todo: this fails: Not implemented
    f := 1.0;
    g :: false;
}
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(
            code, result, Scope(code: [
            ProcedureDeclaration(
                id: "__global_func_main", name: "main", arguments: [],
                returnType: .void, flags: [], scope: Scope(code: [
    VariableDeclaration(name: "a", expType: .string, flags: [], expression: nil),
    VariableDeclaration(name: "b", expType: .int, flags: [], expression: IntLiteral(value: 1)),
    VariableDeclaration(name: "c", expType: .string, flags: [.isConstant], expression: StringLiteral(value: "hello")),
//    VariableDeclaration(name: "d", expType: .int, flags: [], expression: IntLiteral(value: 1)),
//    VariableDeclaration(name: "e", expType: .bool, flags: [.isConstant], expression: BoolLiteral(value: true)),
    VariableDeclaration(name: "f", expType: .float, flags: [], expression: FloatLiteral(value: 1)),
    VariableDeclaration(name: "g", expType: .bool, flags: [.isConstant], expression: BoolLiteral(value: false)),
                ])),
        ]))
    }
    
    func testFunctionDeclaration() {
        let code = """
func print1(format: String, arguments: Int32, ...) #foreign
func print2(format: String, arguments: Int32) {  }
func print3() { x :: 1; }
"""
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Scope(code: [
            ProcedureDeclaration(
                id: "__global_func_print1", name: "print1", arguments: [.string, .int],
                returnType: .void, flags: [.isVarargs, .isForeign], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print2", name: "print2", arguments: [.string, .int],
                returnType: .void, flags: [], scope: .empty),
            ProcedureDeclaration(
                id: "__global_func_print3", name: "print3", arguments: [],
                returnType: .void, flags: [], scope: Scope(code: [
                    VariableDeclaration(name: "x", expType: .int, flags: [.isConstant],
                                        expression: IntLiteral(value: 1))
                ])),
        ]))
    }
    
    func testStructDeclaration() {
        // @Incomplete: finish this test
        let code = """
        struct c { a: String; b :: 1; }
        """
        let tokens = try! Lexer(code).analyze().get()
        let result = Parser(tokens).parse()
        
        printResultCase(code, result, Scope(code: [
            StructDeclaration(name: "c", members: [
                VariableDeclaration(name: "a", expType: .string,
                                    flags: [], expression: nil),
                VariableDeclaration(name: "b", expType: .int,
                                    flags: .isConstant, expression: IntLiteral(value: 1))
            ])
        ]))
    }
}
