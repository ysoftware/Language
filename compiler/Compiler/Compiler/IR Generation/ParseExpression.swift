//
//  ParseExpression.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

internal extension IR {

    /// Process an expression and return the code of the expression and the final IR value
    ///
    /// Example 1
    ///   for an expression of `int literal of 5`
    ///   the return value will be: `code = nil, value = "5"`
    ///
    /// Example 2
    /// for an expression of `string literal of "123"`
    ///   the return value will be: `code = "%1 = getelementptr .... ", value = "%1"`
    ///
    /// Example 3
    /// for an expression of `variable "a" of Int32`
    ///   the return value will be: `code = "%1 = load i32, i32* %a", value = "%1"`
    ///
    func getExpressionResult(
        _ expression: Expression, ident: Int) -> (code: String?, value: String) {
        let identation = String(repeating: "\t", count: ident)
        
        // All expressions go here
        switch expression {
            
        case let literal as IntLiteral:
            return (nil, "\(literal.value)")
            
        case let variable as Value:
            var code = ""
            let type = matchType(variable.exprType)
            let argCount = count()
            code += "%\(argCount) = load \(type), \(type)* %\(variable.name)"
            return (code, "%\(argCount)")
            
        case let literal as BoolLiteral:
            return (nil, "\(literal.value)")

        case let call as ProcedureCall:
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
            var code = "\n"
            var arguments: [String] = []
            
            for arg in call.arguments {
                code += "\(identation); argument \(matchType(arg.exprType))\n"

                // @Todo: don't load the same value argument
                // if passed twice, like a = add(a, a)
                
                // @Todo: dereference all arguments passed by value
                // for now, doing that manually
                
                if let arg = arg as? Value {
                    if arg.exprType.equals(to: .string) {
                        
                        // @Todo: make it work with dynamic strings somehow
                        // I don't think we have to calculate its length before doing this?
                        // there has to be another way!
                        
                        // @Todo: make it work with all other references
                        // now this only works with references to constant string literals
                        // by 'hacky' keeping a list of those while parsing AST
                        
                        // @Todo: should we emit a string literal here, not expect AST to do it for us?
                        // if so, emit a new literal only if a literal with the same value does not exist yet
                        guard let literal = stringLiterals[arg.name] else {
                            report("Undefined symbol \(arg.name)")
                        }
                        
                        let argCount = count()
                        let length = literal.value.count + 1 // @Todo: properly check null termination for strings
                        code += "\(identation)%\(argCount) = getelementptr [\(length) x i8], [\(length) x i8]* @\(arg.name), i32 0, i32 0"
                        arguments.append("i8* %\(argCount)")
                    }
                    else {
                        
                        let type = matchType(arg.exprType)
                        let (eCode, eVal) = getExpressionResult(arg, ident: ident)
                        eCode.map { code += $0 }
                        arguments.append("\(type) \(eVal)")
                    }
                }
                else {
                    let (eCode, eValue) = getExpressionResult(arg, ident: ident)
                    if let eCode = eCode {
                        code += "\(identation); argument\n"
                        code += "\(identation)\(eCode)"
                    }
                    arguments.append("\(matchType(arg.exprType)) \(eValue)")
                }
                code += "\n"
            }
            
            let returnType = matchType(procedure.returnType)
            let argValues = arguments.joined(separator: ", ")
            let argumentsString = getProcedureArgumentString(from: procedure, printName: false)
            
            var value = ""
            code += "\(identation); procedure \(procedure.name)\n"
            if call.exprType.equals(to: .void) {
                code += "\(identation)call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            }
            else {
                let resultCount = count()
                value = "%\(resultCount)"
                code += "\(identation)\(value) = call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            }
            return (code, value)
            
        case let op as UnaryOperator:
            let (load, val) = getExpressionResult(op.argument, ident: ident)
            
            var code = "\n"
            code += "\(identation); unary operator: \(op.name)\n"
            let counter = count()
            let value = "%\(counter)"
            
            // pointer dereference (*a)
            if op.name == "*" {
                load.map { code += "\(identation)\($0)\n" }
                code += "\(identation)\(value) = load \(matchType(op.exprType)), \(matchType(op.operatorType)) \(val)"
            }
            else {
                report("Unsupported expression:\n\(expression)")
            }
            
            return (code, value)
            
        case let op as BinaryOperator:
            var lValue = "", rValue = ""
            var loadL: String?, loadR: String?
            let (l, r) = op.arguments
            (loadL, lValue) = getExpressionResult(l, ident: ident)
            (loadR, rValue) = getExpressionResult(r, ident: ident)
            
            let resultCount = count()
            let instr: String = instruction(for: op.name, type: op.operatorType)
            let workingType = matchType(op.operatorType)
            let result = "%\(resultCount) = \(instr) \(workingType) \(lValue), \(rValue)"
            let value = "%\(resultCount)"
            
            var code = "\n"
            code += "\(identation); binary operator: \(op.name)\n"
            loadL.map { code += "\(identation)\($0)\n" }
            loadR.map { code += "\(identation)\($0)\n" }
            code += "\(identation)\(result)"
            return (code, value)
            
        default:
            report("Unsupported expression:\n\(expression)")
        }
    }
    
    func getProcedureArgumentString(from procedure: ProcedureDeclaration, printName: Bool) -> String {
        var arguments = procedure.arguments.map { (arg: Value)->String in
            var str = "\(matchType(arg.exprType))"
            if printName { str.append(" %\(arg.name)") }
            return str
        }
        if procedure.flags.contains(.isVarargs) {
            arguments.append("...")
        }
        let argumentsString = arguments.joined(separator: ", ")
        return argumentsString
    }
}
