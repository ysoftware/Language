//
//  ParseExpression.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

internal extension IR {
    
    // All expressions go here
    func getExpressionResult(
        _ expression: Expression, ident: Int) -> (code: String?, value: String) {
        let identation = String(repeating: "\t", count: ident)
        
        switch expression {
        case let literal as IntLiteral:
            return (nil, "\(literal.value)")
            
        case let variable as Argument:
            return (nil, "%\(variable.name)")
            
        case let call as ProcedureCall:
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
            var code = "\n"
            var arguments: [String] = []
            
            // @Todo: dereference all arguments passed by value
            // for now, doing that manually
            
            // is there even such a thing? passing something by value?
            // in IR values are a completely different thing (SSA)
            
            for arg in call.arguments {
                
                code += "\(identation); argument \(arg.type.name)\n"
                
                if arg.type == .string {
                    
                    // @Todo: make it work with dynamic strings somehow
                    // I don't think we have to calculate its length before doing this?
                    // there has to be another way!
                    
                    // @Todo: make it work with all other references
                    // now this only works with references to constant string literals
                    // by 'hacky' keeping a list of those while parsing AST
                    
                    guard let literal = stringLiterals[arg.name] else {
                        report("Undefined symbol \(arg.name)")
                    }
                    
                    let argCount = count()
                    let length = literal.value.count
                    code += "\(identation)%\(argCount) = getelementptr [\(length) x i8], [\(length) x i8]* @\(literal.id), i32 0, i32 0"
                    
                    arguments.append("i8* %\(argCount)")
                }
                else {
                    let argCount = count()
                    let type = matchType(arg.type.name)
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
            let workingType = matchType(op.operatorType.name)
            
            let l = op.arguments.0
            let r = op.arguments.1
            let (leCode, leValue) = getExpressionResult(l, ident: ident)
            let (reCode, reValue) = getExpressionResult(r, ident: ident)
            
            // @Incomplete: this only takes pointers, doesn't work with int literals
            // these are identifiers or values (if literals)
            // passed to the operator
            
            var lCount = "", rCount = ""
            var loadL: String?, loadR: String?
            
            if l is IntLiteral {
                lCount = leValue
            }
            else {
                lCount = "%\(count())"
                loadL = "\(lCount) = load \(matchType(l.type.name)), \(matchType(l.type.name))* \(leValue)"
            }
            
            if r is IntLiteral {
                rCount = reValue
            }
            else {
                rCount = "%\(count())"
                loadR = "\(rCount) = load \(matchType(r.type.name)), \(matchType(r.type.name))* \(reValue)"
            }
            
            let resultCount = count()
            let instruction: String = op.name.int
            let result = "%\(resultCount) = \(instruction) \(workingType) \(lCount), \(rCount)"
            let value = "%\(resultCount)"
            
            var code = "\n"
            code += "\(identation); binary operator: \(op.name)\n"
            leCode.map { code += "\(identation)\($0)\n" }
            loadL.map { code += "\(identation)\($0)\n" }
            reCode.map { code += "\(identation)\($0)\n" }
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
