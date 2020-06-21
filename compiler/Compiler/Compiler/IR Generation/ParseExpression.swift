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
    func getExpressionResult(_ expression: Expression, ident: Int) -> (code: String?, value: String) {
        let identation = string(for: ident)
        var code = ""

        // All expressions go here
        switch expression {
            
        case let literal as IntLiteral:
            return (nil, "\(literal.value)")
            
        case let variable as Value:
            let type = matchType(variable.exprType)
            let argValue = "%\(count())"
            code += "\(argValue) = load \(type), \(type)* %\(variable.name)"
            return (code, argValue)
            
        case let call as ProcedureCall:
            if internalProcedures.contains(call.name) { return doInternalProcedure(call, ident: ident) }
            
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
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
                        
                        let argValue = "%\(count())"
                        let length = literal.value.count + 1 // @Todo: properly check null termination for strings
                        code += "\(identation)\(argValue) = getelementptr [\(length) x i8], [\(length) x i8]* @\(arg.name), i32 0, i32 0"
                        arguments.append("i8* \(argValue)")
                    }
                    else {
                        
                        let type = matchType(arg.exprType)
                        let (eCode, eVal) = getExpressionResult(arg, ident: ident)
                        eCode.map { code += "\(identation)\($0)" }
                        arguments.append("\(type) \(eVal)")
                    }
                }
                else {
                    let (eCode, eValue) = getExpressionResult(arg, ident: ident)
                    if let eCode = eCode {
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
                value = "%\(count())"
                code += "\(identation)\(value) = call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            }
            return (code, value)
            
            
        case let access as MemberAccess:
            // this is member access as expression, IRGen for the rValue member access is in another place
            
            let (intermediateCode, memberPointerValue) = getMemberPointerValue(of: access, with: ident)
            code += intermediateCode
            
            let value = "%\(count())"
            let memberType = matchType(access.exprType)
            code += "\(identation)\(value) = load \(memberType), \(memberType)* \(memberPointerValue)\n"
            
            return (code, value)
            
        case let op as UnaryOperator:
            code += "\(identation); unary operator: \(op.name)\n"
            var value = ""
            
            // pointer dereference (*a)
            if op.name == "*" {
                let (load, val) = getExpressionResult(op.argument, ident: ident)
                value = "%\(count())"
                load.map { code += "\(identation)\($0)\n" }
                code += "\(identation)\(value) = load \(matchType(op.exprType)), \(matchType(op.operatorType)) \(val)"
            }
            else if op.name == "&" {
                if let variable = op.argument as? Value {
                    value = "%\(variable.name)"
                }
                else {
                    let (load, val) = getExpressionResult(op.argument, ident: ident)
                    load.map { code += "\(identation)\($0)\n" }
                    value = val
                }
            }
            else {
                report("Unsupported expression:\n\(expression)")
            }
            
            return (code, value)
            
        case let op as BinaryOperator:
            
            if let (load, resultValue) = specialCase(for: op.name, type: op.operatorType, arguments: op.arguments) {
                
                // @Todo: don't pass identation, but add it afterwards (everywhere)
                
                code += load
                return (code, resultValue)
            }
            
            var lValue = "", rValue = ""
            var loadL: String?, loadR: String?
            let (l, r) = op.arguments
            (loadL, lValue) = getExpressionResult(l, ident: ident)
            (loadR, rValue) = getExpressionResult(r, ident: ident)
            
            code += "\(identation); binary operator: \(op.name)\n"
            loadL.map { code += "\(identation)\($0)\n" }
            loadR.map { code += "\(identation)\($0)\n" }
            
            let resultValue = "%\(count())"
            let instr = instruction(for: op.name, type: op.operatorType)
            let workingType = matchType(op.operatorType)
            let result = "\(resultValue) = \(instr) \(workingType) \(lValue), \(rValue)"
            let value = "\(resultValue)"
            
            code += "\(identation)\(result)"
            return (code, value)
            
        case is VoidLiteral:
            return (nil, "void")
            
        case is NullLiteral:
            return (nil, "null")
            
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
    
    /// Value is the pointer to the member, and the code is what's required to search for it
    func getMemberPointerValue(of access: MemberAccess, with ident: Int) -> (code: String, value: String) {
        guard let memberIndex = access.memberIndex else { report("Member access index is not set before IR Gen stage") }
        let identation = string(for: ident)
        
        var code = ""

        let baseType = matchType(access.base.exprType)
        var base = ""
        if let value = access.base as? Value {
            base = "%\(value.name)"
        }
        else if let nestedAccess = access.base as? MemberAccess {
            let (load, val) = getMemberPointerValue(of: nestedAccess, with: ident)
            code += load
            base = val
        }
        else {
            let (load, val) = getExpressionResult(access.base, ident: ident)
            load.map { code += "\(identation)\($0)\n" }
            base = val
        }
        
        code += "\(identation); member access \(access.base.exprType.typeName).\(access.memberName)\n"
        let memberPointerValue = "%\(count())"
        
        let index0 = (access.base.exprType as? PointerType)?.pointeeType is StructureType ? "" : "i32 0, "
        code += "\(identation)\(memberPointerValue) = getelementptr \(baseType), \(baseType)* \(base), \(index0)i32 \(memberIndex)\n"
        
        return (code, memberPointerValue)
    }
}

func string(for ident: Int) -> String {
    String(repeating: "    ", count: ident)
}
