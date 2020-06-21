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
        
        // @Todo: test member access: both expression and rvalue
        
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
        
        if i.failed != 0 { print("\(i.failed) parser test\(plural(i.failed)) have failed!".color(.lightRed)) }
        else { print("All parser tests have passed.".color(.lightGreen)) }
    }
    
    func printErrorCase(caseName: String = #function, _ code: String,
                        _ resultAST: Result<Code, ParserError>, _ expect: ParserError) {
        
        // @Todo: error testing
        // @Todo: test exact cursors
        
        switch resultAST {
        case .success(let result):
            failed += 1
            
            print("\(caseName)".color(.lightRed))
            print("\(code)\n".color(.cyan))
            print("Expected error:", expect.message, "\n===".color(.darkGray))
            print(result)
            print("===\n\n".color(.darkGray))
            
        case .failure(let error):
            if expect == error {
                guard PrintPasses else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)".color(.darkGray))
                return
            }
            print("\(caseName)\n".color(.lightRed))
            error.context.map { print("Error context: ", $0) }
            print("\(code)\n".color(.cyan))
            print("Expected error:", expect.message, "\n===".color(.darkGray))
            print("Received error:", error.message)
            print("===\n\n".color(.darkGray))
        }
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Code, ParserError>, _ expect: Code) {
        
        switch resultAST {
        case .failure(let error):
            failed += 1
            print("\n \(caseName)\nUnexpected error @ \(error.startCursor)-\(error.endCursor)\n")
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
                print("\n\(caseName)".color(.lightRed))
                print("\"\(code)\"\n".color(.cyan))
                if result.statements.count != expect.statements.count {
                    print("Counts don't match:".color(.lightGray),
                    result.statements.count,
                    "Expected:".color(.lightGray),
                    expect.statements.count,
                    "\n===".color(.darkGray))
                    print(result)
                    print("===\n\n".color(.darkGray))
                }
                else {
                    for i in 0..<result.statements.count {
                        if !expect.equals(to: result) {
                            print("Mismatch in:\n".color(.lightGray),
                                  result.statements[i],
                                  "\nExpected:\n".color(.lightGray),
                                  expect.statements[i],
                                  "\n\n")
                        }
                    }
                }
            }
            else {
                guard PrintPasses else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)".color(.lightGray))
            }
        }
    }
    
    func int(_ val: Int) -> IntLiteral { IntLiteral(value: val) }
    func bool(_ val: Bool) -> IntLiteral { IntLiteral(value: val ? 1 : 0, exprType: .bool) }
    func string(_ val: String) -> StringLiteral { StringLiteral(value: val) }
    func float(_ val: Float64) -> FloatLiteral { FloatLiteral(value: val) }
    func val(_ name: String, _ type: Type) -> Value { Value(name: name, exprType: type) }
    func ret(_ expr: Expression) -> Return { Return(value: expr) }
    
    func main(_ code: [Statement]) -> ProcedureDeclaration {
        ProcedureDeclaration(id: "main", name: "main", arguments: [],
                              returnType: .void, flags: [], scope: Code(code))
    }
    
    func vDecl(_ name: String, _ type: Type, _ expr: Expression?, const: Bool = false) -> VariableDeclaration {
        VariableDeclaration(name: name, exprType: type, flags: const ? [.isConstant] : [], expression: expr)
    }
    
    func vAssign(_ name: String, _ expr: Expression) -> Assignment {
        Assignment(receiver: val(name, expr.exprType), expression: expr)
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
