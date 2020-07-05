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

    func testGenericStructUsage() {
        let code = """
        struct Node<Value> { next: Node<Value>*; value: Value; }
        func main() {
            list_int := new Node<Int>;
            int := list_int.value;

            list_list_int := new Node<Node<Int>>;
            int = list_list_int.value.value;
        }
        """

        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)

        printResultCase(code, result, Code([
            StructDeclaration(name: "Node", members: [
                vDecl("next", pointer(structure("Node", [alias("Value")]))),
                vDecl("value", alias("Value")),
            ], genericTypes: ["Value"]),

            main([
                vDecl("list_int", pointer(structure("Node", [int])), New(type: structure("Node", [int]))),
                vDecl("int", int, MemberAccess(base: val("list_int", pointer(structure("Node", [int]))),
                                               memberName: "value", memderIndex: 1, exprType: int)),

                vDecl("list_list_int", pointer(structure("Node", [structure("Node", [int])])),
                      New(type: structure("Node", [structure("Node", [int])]))),
                vAssign("int",
                        MemberAccess(base:
                            MemberAccess(base: val("list_list_int", pointer(structure("Node", [structure("Node", [int])]))),
                            memberName: "value", memderIndex: 1, exprType: structure("Node", [int])),
                        memberName: "value", memderIndex: 1, exprType: int)),

                ret(VoidLiteral())
            ])
        ]))
    }

    func testGenericStructDecl() {
        let code = "struct A<T> { a: A<Int>; b: A<Int>*; c: T; d: T*; e: A<T>; f: A<T*>; g: A<Int*>; h: A<A<Int>>; }"

        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)

        printResultCase(code, result, Code([
            StructDeclaration(name: "A", members: [
                vDecl("a", structure("A", [int])),
                vDecl("b", pointer(structure("A", [int]))),
                vDecl("c", alias("T")),
                vDecl("d", pointer(alias("T"))),
                vDecl("e", structure("A", [alias("T")])),
                vDecl("f", structure("A", [pointer(alias("T"))])),
                vDecl("g", structure("A", [pointer(int)])),
                vDecl("h", structure("A", [structure("A", [int])])),
            ], genericTypes: ["T"])
        ]))
    }
    
    func testMemberAccess() {
        let code = """
        struct Vector { x: Int; y: Int; }
        func main() { vec : Vector; x := vec.x; vec.x = x; }
        """
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let accessX = MemberAccess(base: val("vec", structure("Vector")),
                                   memberName: "x", memderIndex: 0, exprType: int)
        
        printResultCase(code, result, Code([
            StructDeclaration(name: "Vector", members: [
                vDecl("x", int, nil),
                vDecl("y", int, nil)
            ], genericTypes: []),
            main([
                vDecl("vec", structure("Vector"), nil),
                vDecl("x", int, accessX),
                rValAssign(accessX, val("x", int)),
                ret(VoidLiteral())
            ])
        ]))
    }
    
    func testVariableDeclaration() {
        let code = """
        func main() { a : String; b := 1; c :: 1; d : Int = 1;
        e : Bool : true; f := 1.0; g :: false; h :: 5_000_000_000_000; i : Int8*; }
        """
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", string, nil), vDecl("b", int, i(1)),
            vDecl("c", int, i(1), const: true), vDecl("d", int, i(1)),
            vDecl("e", bool, b(true), const: true), vDecl("f", float, f(1)),
            vDecl("g", bool, b(false), const: true),
            vDecl("h", int64, i(5_000_000_000_000), const: true),
            vDecl("i", pointer(int8), nil),
            ret(VoidLiteral())
        ])]))
    }

    func testVariableAssign() {
        let code = "func main() { a := 1; a = a + 1; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", int, i(1)),
            vAssign("a", binop("+", int, (val("a", int), i(1)))),
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
                id: "print1", name: "print1", arguments: [val("format", string), val("arguments", int32)],
                returnType: void, flags: [.isVarargs, .isForeign], scope: .empty),
            ProcedureDeclaration(
                id: "print2", name: "print2", arguments: [val("format", string), val("arguments", int32)],
                returnType: void, flags: [], scope: Code([ ret(VoidLiteral()) ])),
            ProcedureDeclaration(
                id: "print3", name: "print3", arguments: [],
                returnType: void, flags: [], scope: Code([
                    vDecl("x", int, i(1), const: true), ret(VoidLiteral())
                ])),
        ]))
    }
    
    func testStructDeclaration() {
        // @Todo: finish this test
        let code = "x := 1.0; struct A { a: String; b :: 1; c := b; d := x; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            vDecl("x", float, f(1)),
            StructDeclaration(name: "A", members: [
                vDecl("a", string, nil),
                vDecl("b", int, i(1), const: true),
                vDecl("c", int, val("b", int)),
                vDecl("d", float, val("x", float)),
            ], genericTypes: [])
        ]))
    }
    
    func testTypeInferenceGlobalProc() {
        // types of a and b are inferred from the known procedure declarations (1st pass)
        
        let code = """
        func getInt() -> Int { return 1; }
        func getFloat() -> Float { return 0.2; }
        struct Value { a := getInt(); b := getFloat(); }
        """
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "getInt", name: "getInt", arguments: [],
                returnType: int, flags: [], scope: Code([Return(value: i(1))])),
            ProcedureDeclaration(
                id: "getFloat", name: "getFloat", arguments: [],
                returnType: float, flags: [], scope: Code([
                    Return(value: f(0.2))
                ])),
            StructDeclaration(name: "Value", members: [
                vDecl("a", int, ProcedureCall(name: "getInt", exprType: int, arguments: [])),
                vDecl("b", float, ProcedureCall(name: "getFloat", exprType: float, arguments: []))
            ], genericTypes: [])
        ]))
    }
    
    func testTypeInference() {
        let code = "c:= 1; func main() { a := c; b := a; }"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(
            code, result, Code([
                vDecl("c", int, i(1)),
                main([
                    vDecl("a", int, val("c", int)),
                    vDecl("b", int, val("a", int)),
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
                Condition(condition: b(true), block: Code([
                    vDecl("a", int, i(1)),
                    Condition(condition: b(false), block: Code([
                        vDecl("b", int, val("a", int)),
                    ]), elseBlock: .empty)
                ]), elseBlock: Code([
                    vDecl("c", unresolved, val("a", unresolved))
                ])),
                ret(VoidLiteral())
            ])]))
    }
    
    func testWhileLoop() {
        let code = "func main() { while (true) { }}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)

        printResultCase(code, result, Code([ main([
            WhileLoop(userLabel: nil, condition: b(true), block: .empty),
            ret(VoidLiteral())
        ])]))
    }
    
    func testWhileLoopBreak() {
        let code = "func main() { loop: while (true) { loop1: while (true) { break loop; }}}"
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            WhileLoop(userLabel: "loop", condition: b(true), block: Code([
                WhileLoop(userLabel: "loop1", condition: b(true), block: Code([
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
            WhileLoop(userLabel: "loop", condition: b(true), block: Code([
                WhileLoop(userLabel: "loop1", condition: b(true), block: Code([
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
            vDecl("a", int, i(1)),
            vDecl("b", int, unop("-", int, val("a", int))),
            ret(VoidLiteral())
        ])]))
    }
    
    func testPrecedence() {
        let code = "func main() { a := (1 + 3) * (1 + 7 / -(5 + 3)) % 100 == 0; }"
        
        let op11 = binop("+", int, (i(5), i(3)))
        let op12 = unop("-", int, op11)
        let op13 = binop("/", int, (i(7), op12))
        let op14 = binop("+", int, (i(1), op13))
        
        let op0 = binop("+", int, (i(1), i(3)))
        let op2 = binop("*", int, (op0, op14))
        let op3 = binop("%", int, (op2, i(100)))
        let op4 = binop("==", bool, (op3, i(0)))
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([main([
            vDecl("a", bool, op4),
            ret(VoidLiteral())
        ])]))
    }
    
    func testBinaryOperators() {
        let code = "func getInt() -> Int { return 2; } func main() { a := 2 * 3 + 2 * getInt(); b: = a + 2 * 2; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let mul1 = binop("*", int, (i(2), i(3)))
        let mul2 = binop("*", int, (i(2), call("getInt", int)))
        let mul3 = binop("*", int, (i(2), i(2)))

        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "getInt", name: "getInt", arguments: [],
                returnType: int, flags: [], scope: Code([ ret(i(2)) ])),
            main([
                vDecl("a", int, binop("+", int, (mul1, mul2))),
                vDecl("b", int, binop("+", int, (val("a", int), mul3))),
                ret(VoidLiteral())
            ])
        ]))
    }
    
    func testBrackets() {
        let code = "func main() { a := (1+2)*(3)+5; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let binop1 = binop("+", int, (i(1), i(2))) // 1 + 2
        let binop2 = binop("*", int, (binop1, i(3))) // (1+2) * (3)
        let binop3 = binop("+", int, (binop2, i(5))) // ((1+2)+(3)) + 5
        
        printResultCase(code, result, Code([ main([
            vDecl("a", int, binop3),
            ret(VoidLiteral())
        ])]))
    }
    
    func testBinopLiteralConversion() {
        let code = "func main() { a := 1 + -(1) + 1.5; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let binop1 = binop("+", float, (f(1), unop("-", float, f(1))))
        let binop2 = binop("+", float, (binop1, f(1.5)))
        
        printResultCase(code, result, Code([ main([
            vDecl("a", float, binop2),
            ret(VoidLiteral())
        ])]))
    }
    
    func testReturnTypeLiteralConversion() {
        let code = "func getFloat() -> Float { return 1; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([
            ProcedureDeclaration(
                id: "getFloat", name: "getFloat", arguments: [],
                returnType: float, flags: [], scope: Code([ Return(value: f(1) )]))
        ]))
    }
    
    func testErrorReturnTypeNotMatching() {
        let code = "func main() -> Float { return \"string\"; }"
        
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        let error = ParserError(startCursor: Cursor(character: 30),
                                endCursor: Cursor(character: 37),
                                message: em.returnTypeNotMatching(float, string))
        printErrorCase(code, result, error)
    }
    
    func testPointers() {
        let code = """
        func main() {
            a : Int**;
            b : Int*   = *a; // getting value of 'a'
            c : Int*** = &a; // getting a pointer to 'a'
        }
        """
        let tokens = try! Lexer(code).analyze().tokens
        let result = parserResult(Parser(tokens).parse)
        
        printResultCase(code, result, Code([ main([
            vDecl("a", pointer(pointer(int)), nil),
            vDecl("b", pointer(int),  unop("*", pointer(int), val("a", pointer(pointer(int))))),
            vDecl("c", pointer(pointer(pointer(int))),
                  unop("&", pointer(pointer(pointer(int))), val("a", pointer(pointer(int))))),
            ret(VoidLiteral())
        ])]))
    }
}
