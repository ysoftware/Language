//
//  ParseExpression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
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
    func getExpressionResult(
        _ expression: Expression, ident: Int) -> (code: String?, value: String) {
        let identation = String(repeating: "\t", count: ident)
        
        // All expressions go here
        switch expression {
            
        case let literal as IntLiteral:
            return (nil, "\(literal.value)")
            
        case let variable as Argument:
            return (nil, "%\(variable.name)")
            
        case let literal as BoolLiteral:
            return (nil, "\(literal.value)")

        case let call as ProcedureCall:
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
            var code = "\n"
            var arguments: [String] = []
            
            for arg in call.arguments {
                code += "\(identation); argument \(arg.expType.name)\n"

                // @Todo: dereference all arguments passed by value
                // for now, doing that manually
                
                // is there even such a thing? passing something by value?
                // in IR values are a completely different thing (SSA)
                
                if arg.expType == .string {
                    
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
                    let length = literal.value.count
                    code += "\(identation)%\(argCount) = getelementptr [\(length) x i8], [\(length) x i8]* @\(arg.name), i32 0, i32 0"
                    arguments.append("i8* %\(argCount)")
                }
                else {
                    let argCount = count()
                    let type = matchType(arg.expType.name)
                    code += "\(identation)%\(argCount) = load \(type), \(type)* %\(arg.name)"
                    arguments.append("\(type) %\(argCount)")
                }
                code += "\n"
            }
            
            let returnType = matchType(procedure.returnType.name)
            let argValues = arguments.joined(separator: ", ")
            let argumentsString = getProcedureArgumentString(from: procedure)
            let resultCount = count()
            let value = "%\(resultCount)"
            
            code += "\(identation); procedure \(procedure.name)\n"
            code += "\(identation)\(value) = call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            return (code, value)
            
        case let op as BinaryOperator:
            var lValue = "", rValue = ""
            var loadL: String?, loadR: String?
            let (l, r) = op.arguments
            let (lExpCode, lExpVal) = getExpressionResult(l, ident: ident)
            let (rExpCode, rExpVal) = getExpressionResult(r, ident: ident)
            
            if l is IntLiteral { lValue = lExpVal }
            else {
                lValue = "%\(count())"
                loadL = "\(lValue) = load \(matchType(l.expType.name)), \(matchType(l.expType.name))* \(lExpVal)"
            }
            
            if r is IntLiteral { rValue = rExpVal }
            else {
                rValue = "%\(count())"
                loadR = "\(rValue) = load \(matchType(r.expType.name)), \(matchType(r.expType.name))* \(rExpVal)"
            }
            
            let resultCount = count()
            let instruction: String = op.name.int
            let workingType = matchType(op.operatorType.name)
            let result = "%\(resultCount) = \(instruction) \(workingType) \(lValue), \(rValue)"
            let value = "%\(resultCount)"
            
            var code = "\n"
            code += "\(identation); binary operator: \(op.name)\n"
            lExpCode.map { code += "\(identation)\($0)\n" }
            loadL.map { code += "\(identation)\($0)\n" }
            rExpCode.map { code += "\(identation)\($0)\n" }
            loadR.map { code += "\(identation)\($0)\n" }
            code += "\(identation)\(result)"
            return (code, value)
            
        default:
            report("Unsupported expression\n\(expression)")
        }
    }
    
    func getProcedureArgumentString(from procedure: ProcedureDeclaration) -> String {
        var argumentNames = procedure.arguments.map(\.name).map(matchType)
        if procedure.flags.contains(.isVarargs) {
            argumentNames.append("...")
        }
        let arguments = argumentNames.joined(separator: ", ")
        return arguments
    }
}
