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
    func getExpressionResult(_ expression: Expression, indentLevel: Int = 0) -> (code: String?, value: String) {
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
            
        case let sizeof as SizeOf:
            let ptr = "%\(count())"
            let value = "%\(count())"
            code += "; sizeof \(sizeof.type.typeName)\n"
            code += "\(ptr) = getelementptr \(matchType(sizeof.type)), \(matchType(sizeof.type))* null, i32 1\n"
            code += "\(value) = ptrtoint \(matchType(sizeof.type))* \(ptr) to i32\n"
            return (code, value)
            
        case let call as ProcedureCall:
            if internalProcedures.contains(where: { $0.name == call.name }) { return doInternalProcedure(call) }
            
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
            var arguments: [String] = []
            
            for arg in call.arguments {
                code += "; argument \(matchType(arg.exprType))\n"
                
                // @Todo: don't load the same value argument
                // if passed twice, like a = add(a, a)
                
                // @Todo: dereference all arguments passed by value
                // for now, doing that manually
                
                if let arg = arg as? Value {
                    // @Todo: somehow check if it's a string literal
                    // else we just load the value
                    if arg.exprType.equals(to: .string) {
                        guard let literal = stringLiterals[arg.name] else {
                            report("Undefined symbol \(arg.name)")
                        }
                        
                        let argValue = "%\(count())"
                        let length = literal.value.count + 1
                        code += "\(argValue) = getelementptr [\(length) x i8], [\(length) x i8]* @\(arg.name), i32 0, i32 0"
                        arguments.append("i8* \(argValue)")
                    }
                    else {
                        
                        let type = matchType(arg.exprType)
                        let (eCode, eVal) = getExpressionResult(arg)
                        eCode.map { code += "\($0)" }
                        arguments.append("\(type) \(eVal)")
                    }
                }
                else {
                    let (eCode, eValue) = getExpressionResult(arg)
                    if let eCode = eCode {
                        code += "\(eCode)"
                    }
                    arguments.append("\(matchType(arg.exprType)) \(eValue)")
                }
                code += "\n"
            }
            
            let returnType = matchType(procedure.returnType)
            let argValues = arguments.joined(separator: ", ")
            let argumentsString = getProcedureArgumentString(from: procedure, printName: false)
            
            var value = ""
            code += "; procedure \(procedure.name)\n"
            if call.exprType.equals(to: .void) {
                code += "call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            }
            else {
                value = "%\(count())"
                code += "\(value) = call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            }
            return (code, value)
            
            
        case let access as MemberAccess:
            // this is member access as expression, IRGen for the rValue member access is in another place
            
            let (intermediateCode, memberPointerValue) = getMemberPointerAddress(of: access)
            code += intermediateCode
            
            let value = "%\(count())"
            let memberType = matchType(access.exprType)
            code += "\(value) = load \(memberType), \(memberType)* \(memberPointerValue)"

            return (code, value)
            
        case let op as UnaryOperator:
            var value = ""
            
            // pointer dereference (*a)
            if op.name == UnaryOperator.dereference {
                let (load, val) = getExpressionResult(op.argument)
                value = "%\(count())"
                load.map { code += "\($0)\n" }
                
                code += "; unary operator: * (pointer dereference) \n"
                code += "\(value) = load \(matchType(op.exprType)), \(matchType(op.operatorType)) \(val)"
            }
            else if op.name == UnaryOperator.memoryAddress {
                if let variable = op.argument as? Value {
                    value = "%\(variable.name)"
                }
                else {
                    let (load, val) = getExpressionResult(op.argument)
                    load.map { code += "\($0)\n" }
                    value = val
                }
            }
            else if op.name == UnaryOperator.cast {
                let (load, val) = getExpressionResult(op.argument)
                value = "%\(count())"
                load.map { code += "\($0)\n" }
                code += "; unary operator: cast \n"
                code += "\(value) = bitcast \(matchType(op.argument.exprType)) \(val) to \(matchType(op.exprType))"
            }
            else {
                report("Unsupported expression:\n\(expression)")
            }
            
            return (code, value)
            
        case let op as BinaryOperator:
            
            if let (load, resultValue) = specialCase(for: op.name, type: op.operatorType, arguments: op.arguments) {
                code += load
                return (code, resultValue)
            }
            
            var lValue = "", rValue = ""
            var loadL: String?, loadR: String?
            let (l, r) = op.arguments
            (loadL, lValue) = getExpressionResult(l)
            (loadR, rValue) = getExpressionResult(r)
            
            loadL.map { code += "\($0)\n" }
            loadR.map { code += "\($0)\n" }
            
            code += "; binary operator: \(op.name)\n"
            let resultValue = "%\(count())"
            let instr = instruction(for: op.name, type: op.operatorType)
            let workingType = matchType(op.operatorType)
            let result = "\(resultValue) = \(instr) \(workingType) \(lValue), \(rValue)"
            let value = "\(resultValue)"
            
            code += "\(result)"
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
    
    /// Returns the `pointer to the member`, and the code is what's required to search for it
    func getMemberPointerAddress(of access: MemberAccess) -> (code: String, value: String) {
        guard let memberIndex = access.memberIndex else { report("Member access index is not set before IR Gen stage") }
        var baseType = matchType(access.base.exprType)
        
        var code = ""
        var base = ""
        
        if let value = access.base as? Value {
            base = "%\(value.name)"
        }
        else if let nestedAccess = access.base as? MemberAccess {
            let (load, val) = getMemberPointerAddress(of: nestedAccess)
            code += load
            base = val
        }
        else {
            let (load, val) = getExpressionResult(access.base)
            load.map { code += "\($0)\n" }
            base = val
        }
        
        code += "; member access \(access.base.exprType.typeName).\(access.memberName)\n"
        if let pointer = access.base.exprType as? PointerType { // deref pointer first
            let type = matchType(pointer)
            let deref = base
            base = "%\(count())"
            code += "; dereferencing\n"
            code += "\(base) = load \(type), \(type)* \(deref)\n"
            baseType = matchType(pointer.pointeeType)
        }
        
        let memberPointerValue = "%\(count())"
        code += "\(memberPointerValue) = getelementptr \(baseType), \(baseType)* \(base), i32 0, i32 \(memberIndex)\n"
        
        return (code, memberPointerValue)
    }
}

func indentString(_ string: String, level ident: Int) -> String {
    let indentation = String(repeating: "    ", count: ident)
    return string.split(separator: "\n", omittingEmptySubsequences: false)
        .map { indentation + $0 }.joined(separator: "\n")
}
