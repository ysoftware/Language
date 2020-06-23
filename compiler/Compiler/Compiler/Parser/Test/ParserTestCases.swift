//
//  ParserTestCases.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func parserResult<T>(_ block: () throws -> T) -> Result<T, ParserError> {
    Result(catching: { try block() }).mapError { $0 as! ParserError }
}

extension ParserTest {
    
        func testVariableDeclaration() {
            let code = """
    func main() { a : String; b := 1; c :: "hello"; d : Int = 1;
    e : Bool : true; f := 1.0; g :: false; h :: 5_000_000_000_000; i : Int8*; }
    """
            let tokens = try! Lexer(code).analyze().tokens
            let result = parserResult(Parser(tokens).parse)
            
            printResultCase(code, result, Code([main([
                vDecl("a", .string, nil), vDecl("b", .int, int(1)),
                vDecl("c", .string, string("hello"), const: true), vDecl("d", .int, int(1)),
                vDecl("e", .bool, bool(true), const: true), vDecl("f", .float, float(1)),
                vDecl("g", .bool, bool(false), const: true),
                vDecl("h", .int64, int(5_000_000_000_000), const: true),
                vDecl("i", .pointer(.int8), nil),
                ret(VoidLiteral())
            ])]))
        }

    func testVariableAssign() {
        let code = "func main() { a := 1; a = a + 1; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", .int, int(1)),
            vAssign("a", binop("+", .int, (val("a", .int), int(1)))),
            ret(VoidLiteral())
        ])]))
    }
    
    func testFunctionDeclaration() {
        let code = """
func print1(format: String, arguments: Int32, ...) #foreign;
func print2(format: String, arguments: Int32) {  }
func print3() { x :: 1; }
"""
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "print1", name: "print1", arguments: [val("format", .string), val("arguments", .int32)],
                returnType: .void, flags: [.isVarargs, .isForeign], scope: .empty),
            ProcedureDeclaration(
                id: "print2", name: "print2", arguments: [val("format", .string), val("arguments", .int32)],
                returnType: .void, flags: [], scope: Code([ ret(VoidLiteral()) ])),
            ProcedureDeclaration(
                id: "print3", name: "print3", arguments: [],
                returnType: .void, flags: [], scope: Code([
                    vDecl("x", .int, int(1), const: true), ret(VoidLiteral())
                ])),
        ]))
    }
    
    func testStructDeclaration() {
        // @Todo: finish this test
//        let code = "1struct c { a: String; b :: 1; }" // @Lexer @Todo: this passes (with 1 at the start)
        let code = "x := 1.0; struct A { a: String; b :: 1; c := b; d := x; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            vDecl("x", .float, float(1)),
            StructDeclaration(name: "A", members: [
                vDecl("a", .string, nil),
                vDecl("b", .int, int(1), const: true),
                vDecl("c", .int, val("b", .int)),
                vDecl("d", .float, val("x", .float)),
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
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "getInt", name: "getInt", arguments: [],
                returnType: .int, flags: [], scope: Code([Return(value: int(1))])),
            ProcedureDeclaration(
                id: "getString", name: "getString", arguments: [],
                returnType: .string, flags: [], scope: Code([
                    Return(value: string("hello"))
                ])),
            StructDeclaration(name: "Value", members: [
                vDecl("a", .int, ProcedureCall(name: "getInt", exprType: .int, arguments: [])),
                vDecl("b", .string, ProcedureCall(name: "getString", exprType: .string, arguments: []))
            ])
        ]))
    }
    
    func testTypeInference() {
        let code = "c:= 1; func main() { a := c; b := a; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(
            code, result, Code([
                vDecl("c", .int, int(1)),
                main([
                    vDecl("a", .int, val("c", .int)),
                    vDecl("b", .int, val("a", .int)),
                    ret(VoidLiteral())
                ])
            ]))
    }
    
    func testTypeInference2() {
        // @Todo this test should fail when 2nd pass type inference is implemented
        // this just stops at the type being unresolved
        let code = "func main() { if (true) { a := 1; if (false) { b := a; }} else { c := a; }}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(
            code, result, Code([ main([
                Condition(condition: bool(true), block: Code([
                    vDecl("a", .int, int(1)),
                    Condition(condition: bool(false), block: Code([
                        vDecl("b", .int, val("a", .int)),
                    ]), elseBlock: .empty)
                ]), elseBlock: Code([
                    vDecl("c", .unresolved, val("a", .unresolved))
                ])),
                ret(VoidLiteral())
            ])]))
    }
    
    func testWhileLoop() {
        let code = "func main() { while (true) { }}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)

        printResultCase(code, result, Code([ main([
            WhileLoop(userLabel: nil, condition: bool(true), block: .empty),
            ret(VoidLiteral())
        ])]))
    }
    
    func testWhileLoopBreak() {
        // @Todo: you can pass string literal with no error as while condition
        let code = "func main() { loop: while (true) { loop1: while (true) { break loop; }}}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            WhileLoop(userLabel: "loop", condition: bool(true), block: Code([
                WhileLoop(userLabel: "loop1", condition: bool(true), block: Code([
                    Break(userLabel: "loop")
                ]))
            ])),
            ret(VoidLiteral())
        ])]))
    }
    
    func testWhileLoopContinue() {
        let code = "func main() { loop: while (true) { loop1: while (true) { continue loop; }}}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)

        printResultCase(code, result, Code([main([
            WhileLoop(userLabel: "loop", condition: bool(true), block: Code([
                WhileLoop(userLabel: "loop1", condition: bool(true), block: Code([
                    Continue(userLabel: "loop")
                ]))
            ])),
            ret(VoidLiteral())
        ])]))
    }
    
    func testUnaryOperators() {
        let code = "func main() { a := 1; b := -a; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", .int, int(1)),
            vDecl("b", .int, unop("-", .int, val("a", .int))),
            ret(VoidLiteral())
        ])]))
    }
    
    func testPrecedence() {
        // @Todo: this should result in a expression of type float (because of 0.5)
        // let code = "func main() { a := (1 + 3) * (1 + 7 / -(5 + 3)) % 100 - 0.5; }"
        
        let code = "func main() { a := (1 + 3) * (1 + 7 / -(5 + 3)) % 100 == 0; }"
        
        let op11 = binop("+", .int, (int(5), int(3)))
        let op12 = unop("-", .int, op11)
        let op13 = binop("/", .int, (int(7), op12))
        let op14 = binop("+", .int, (int(1), op13))
        
        let op0 = binop("+", .int, (int(1), int(3)))
        let op2 = binop("*", .int, (op0, op14))
        let op3 = binop("%", .int, (op2, int(100)))
        let op4 = binop("==", .bool, (op3, int(0)))
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", .bool, op4),
            ret(VoidLiteral())
        ])]))
    }
    
    func testBinaryOperators() {
        let code = "func getInt() -> Int { return 2; } func main() { a := 2 * 3 + 2 * getInt(); b: = a + 2 * 2; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let mul1 = binop("*", .int, (int(2), int(3)))
        let mul2 = binop("*", .int, (int(2), call("getInt", .int)))
        let mul3 = binop("*", .int, (int(2), int(2)))

        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "getInt", name: "getInt", arguments: [],
                returnType: .int, flags: [], scope: Code([ ret(int(2)) ])),
            main([
                vDecl("a", .int, binop("+", .int, (mul1, mul2))),
                vDecl("b", .int, binop("+", .int, (val("a", .int), mul3))),
                ret(VoidLiteral())
            ])
        ]))
    }
    
    func testBrackets() {
        let code = "func main() { a := (1+2)*(3)+5; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let binop1 = binop("+", .int, (int(1), int(2))) // 1 + 2
        let binop2 = binop("*", .int, (binop1, int(3))) // (1+2) * (3)
        let binop3 = binop("+", .int, (binop2, int(5))) // ((1+2)+(3)) + 5
        
        printResultCase(code, result, Code([ main([
            vDecl("a", .int, binop3),
            ret(VoidLiteral())
        ])]))
    }
    
    func testBinopLiteralConversion() {
        let code = "func main() { a := 1 + -(1) + 1.5; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let binop1 = binop("+", .float, (float(1), unop("-", .float, float(1))))
        let binop2 = binop("+", .float, (binop1, float(1.5)))
        
        printResultCase(code, result, Code([ main([
            vDecl("a", .float, binop2),
            ret(VoidLiteral())
        ])]))
    }
    
    func testReturnTypeLiteralConversion() {
        let code = "func float() -> Float { return 1; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "float", name: "float", arguments: [],
                returnType: .float, flags: [], scope: Code([ Return(value: float(1) )]))
        ]))
    }
    
    func testErrorReturnTypeNotMatching() {
        let code = "func main() -> Float { return \"string\"; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let error = ParserError(startCursor: Cursor(character: 30),
                                endCursor: Cursor(character: 37),
                                message: em.returnTypeNotMatching(.float, .string))
        printErrorCase(code, result, error)
    }
    
    func testPointers() {
        let code = """
func main() {
    a : Int**;
    b : Int* = *a; // getting a pointer to 'a'
}
"""
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([ main([
            vDecl("a", .pointer(.pointer(.int)), nil),
            vDecl("b", .pointer(.int),  unop("*", .pointer(.int), val("a", .pointer(.pointer(.int))))),
            ret(VoidLiteral())
        ])]))
    }
}
