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
    
    static func run() {
        let i = ParserTest()
        i.failed = 0

        i.testTypeParsing()
        i.testGenericProcedureUsage()
        i.testGenericProcedureDecl()
        i.testGenericStructDecl()
        i.testGenericStructUsage()
        i.testBinopLiteralConversion()
        i.testPointers()
        i.testMemberAccess()
        i.testVariableAssign()
        i.testFunctionDeclaration()
        i.testErrorReturnTypeNotMatching()
        i.testReturnTypeLiteralConversion()
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
        let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])

        switch resultAST {
        case .success(let result):
            failed += 1
            
            print("\(name)".color(.lightRed))
            print("\(code)\n".color(.cyan))
            print("Expected error:", expect.message, "\n===".color(.darkGray))
            print(result.statements.map(\.debugDescription).joined(separator: "\n"))
            print("===\n\n".color(.darkGray))
            
        case .failure(let error):
            if expect == error {
                guard PrintPasses else { return }
                let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])
                print("OK \(name)".color(.darkGray))
                return
            }
            failed += 1
            print("\(name)\n".color(.lightRed))
            error.context.map { print("Error context: ", $0) }
            print("\(code)\n".color(.cyan))
            print("Expected error: \(expect.message)\n".color(.darkGray))
            printParserError(error, code)
        }
    }
    
    func printResultCase(caseName: String = #function,
                         _ code: String,
                         _ resultAST: Result<Code, ParserError>, _ expect: Code) {
        let name = String(caseName[..<caseName.endIndex(offsetBy: -2)])

        switch resultAST {
        case .failure(let pe):
            failed += 1
            print("")
            print(name.color(.lightRed))
            print("\(code)\n".color(.cyan))

            printParserError(pe, code)
            
        case .success(let result):
            if !result.equals(to: expect) {
                failed += 1
                print("\n\(name)".color(.lightRed))
                print("\(code)\n".color(.cyan))
                printMismatches(result.statements, expect.statements)
            }
            else {
                guard PrintPasses else { return }
                print("OK \(name)".color(.lightGray))
            }
        }
    }
    
    private func printMismatches(_ result: [Statement], _ expect: [Statement]) {
        if result.count != expect.count {
            print("Counts don't match:".color(.lightGray), result.count,
            "Expected:".color(.lightGray), expect.count, "\n===".color(.darkGray))
            print(result.map(\.debugDescription).joined(separator: "\n"))
            print("===\n\n".color(.darkGray))
        }
        else {
            for i in 0..<result.count {
                if let resultBlock = result[i] as? Condition, let expectBlock = expect[i] as? Condition {
                    printMismatches(resultBlock.block.statements, expectBlock.block.statements)
                    printMismatches(resultBlock.elseBlock.statements, expectBlock.elseBlock.statements)
                }
                else if let resultBlock = result[i] as? WhileLoop, let expectBlock = expect[i] as? WhileLoop {
                    printMismatches(resultBlock.block.statements, expectBlock.block.statements)
                }
                else if let resultBlock = result[i] as? ProcedureDeclaration, let expectBlock = expect[i] as? ProcedureDeclaration {
                    printMismatches(resultBlock.scope.statements, expectBlock.scope.statements)
                }
                else if !expect[i].equals(to: result[i]) {
                    print("Mismatch in:\n".color(.lightGray), result[i],
                          "\nExpected:\n".color(.lightGray), expect[i], "\n\n")
                }
            }
        }
    }
    
    func i(_ val: Int) -> IntLiteral { IntLiteral(value: val) }
    func b(_ val: Bool) -> IntLiteral { IntLiteral(value: val ? 1 : 0, exprType: bool) }
    func str(_ val: String) -> StringLiteral { StringLiteral(value: val) }
    func f(_ val: Float64) -> FloatLiteral { FloatLiteral(value: val) }
    func val(_ name: String, _ type: Type) -> Value { Value(name: name, id: "", exprType: type) }
    func ret(_ expr: Expression) -> Return { Return(value: expr) }
    
    func main(_ code: [Statement]) -> ProcedureDeclaration {
        ProcedureDeclaration(id: "main", name: "main", arguments: [],
                              returnType: void, flags: [], scope: Code(code))
    }
    
    func vDecl(_ name: String, _ type: Type, _ expr: Expression? = nil, const: Bool = false) -> VariableDeclaration {
        VariableDeclaration(name: name, id: "", exprType: type, flags: const ? [.isConstant] : [], expression: expr)
    }
    
    func vAssign(_ name: String, _ expr: Expression) -> Assignment {
        Assignment(receiver: val(name, expr.exprType), expression: expr)
    }
    
    func rValAssign(_ ast: Ast, _ expr: Expression) -> Assignment {
        Assignment(receiver: ast, expression: expr)
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
