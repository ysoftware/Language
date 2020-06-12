//
//  ParserTest.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 23.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class ParserTest {
    fileprivate var failed = 0
    let em = Parser.ErrorMessage()
    
    static func run() {
        let i = ParserTest()
        i.failed = 0
        
        i.testPointers()
        i.testFunctionDeclaration()
        i.testVariableAssign()
        i.testErrorReturnTypeNotMatching()
        i.testReturnTypeLiteralConversion()
        i.testBinopLiteralConversion()
        i.testPrecedence()
        i.testBinaryOperators()
        i.testBrackets()
        i.testUnaryOperators()
        i.testWhileLoopContinue()
        i.testWhileLoopBreak()
        i.testWhileLoop()
        i.testTypeInference2()
        i.testTypeInference()
        i.testTypeInferenceGlobalProc()
        i.testVariableDeclaration()
        i.testStructDeclaration()
        
        if i.failed != 0 { print("❌ \(i.failed) parser test\(plural(i.failed)) have failed!") }
        else { print("All parser tests have passed.") }
    }
    
    func printErrorCase(caseName: String = #function, _ code: String,
                        _ resultAST: Result<Code, ParserError>, _ expect: ParserError) {
        
        // @Todo: error testing
        // @Todo: test exact cursors
        
        switch resultAST {
        case .success(let result):
            failed += 1
            
            print("❌ \(caseName)")
            print("code: \"\(code)\"\n")
            print("Expected error:", expect.message, "\n===")
            print(result)
            print("===\n\n")
            
        case .failure(let error):
            if expect == error {
                guard PRINT_PASSES else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)")
                return
            }
            print("❌ \(caseName)\n")
            error.context.map { print("Error context: ", $0) }
            print("code: \"\(code)\"\n")
            print("Expected error:", expect.message, "\n===")
            print("Received error:", error.message)
            print("===\n\n")
        }
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Code, ParserError>, _ expect: Code) {
        
        switch resultAST {
        case .failure(let error):
            failed += 1
            print("\n❌ \(caseName)\nUnexpected error @ \(error.startCursor)-\(error.endCursor)\n")
            print(error.message, "\n")
            
            _ = {
                let lines = code.split(separator: "\n")
                let line = lines[error.endCursor.lineNumber-1]
                print("\(line)")
                if error.startCursor.lineNumber == error.endCursor.lineNumber {
                    let startCursor = String(repeating: " ", count: error.startCursor.character) + "^"
                    let endCursor = String(repeating: "^", count: error.endCursor.character-error.startCursor.character)
                    print("\(startCursor)\(endCursor)")
                }
                else {
                    // multiline expression error
                    print(String(repeating: "^", count: error.endCursor.character))
                }
                print("\n\n")
            }()
            
        case .success(let result):
            if !result.equals(to: expect) {
                failed += 1
                print("\n❌ \(caseName)")
                print("\"\(code)\"\n")
                if result.statements.count != expect.statements.count {
                    print("Counts don't match", result.statements.count, "vs expected", expect.statements.count, "\n===")
                    print(result)
                    print("===\n\n")
                }
                else {
                    for i in 0..<result.statements.count {
                        if !expect.equals(to: result) {
                            print("Mismatch in:\n", result.statements[i], "\nExpected:\n", expect.statements[i], "\n\n")
                        }
                    }
                }
            }
            else {
                guard PRINT_PASSES else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)")
            }
        }
    }
    
    func int(_ val: Int) -> IntLiteral { IntLiteral(value: val) }
    func bool(_ val: Bool) -> BoolLiteral { BoolLiteral(value: val) }
    func string(_ val: String) -> StringLiteral { StringLiteral(value: val) }
    func float(_ val: Float) -> FloatLiteral { FloatLiteral(value: val) }
    func val(_ name: String, _ type: Type) -> Value { Value(name: name, exprType: type) }
    func ret(_ expr: Expression) -> Return { Return(value: expr) }
    
    func main(_ code: [Statement]) -> ProcedureDeclaration {
        ProcedureDeclaration(id: "main", name: "main", arguments: [],
                              returnType: .void, flags: [], scope: Code(code))
    }
    
    func vDecl(_ name: String, _ type: Type, _ expr: Expression?, const: Bool = false) -> VariableDeclaration {
        VariableDeclaration(name: name, exprType: type, flags: const ? [.isConstant] : [], expression: expr)
    }
    
    func vAssign(_ name: String, _ expr: Expression) -> VariableAssignment {
        VariableAssignment(receiverId: name, expression: expr)
    }
    
    func binop(_ name: String, _ type: Type, _ arguments: (Expression, Expression)) -> BinaryOperator {
        BinaryOperator(name: name, exprType: type, arguments: arguments)
    }
    
    func unop(_ name: String, _ type: Type, _ argument: Expression) -> UnaryOperator {
        UnaryOperator(name: name, exprType: type, argument: argument)
    }
    
    func call(_ name: String, _ exprType: Type, arguments: Expression...) -> ProcedureCall {
        ProcedureCall(name: name, exprType: exprType, arguments: arguments)
    }
}
