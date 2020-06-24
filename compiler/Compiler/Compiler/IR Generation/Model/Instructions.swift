//
//  BinaryOperators.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//
//

extension IR {

    func specialCase(for operation: String, type: Type, arguments: (Expression, Expression)) -> (code: String, value: String)? {
        if type is PointerType {
            switch operation {
            case "==", "!=":

                var code = ""
                let workingType = matchType(type)
                let instr = instruction(for: operation, type: .int64)

                var lCode: String?, lValue: String = ""
                if let variable = arguments.0 as? Value {
                    lValue = "%\(variable.name)"
                    let lPointer = "%\(count())"
                    code += "\(lPointer) = load \(workingType), \(workingType)* \(lValue)\n"
                    lValue = lPointer
                }
                else {
                    (lCode, lValue) = getExpressionResult(arguments.0)
                    lCode.map { code += "\($0)\n" }
                }

                var rCode: String?, rValue: String = ""
                if let variable = arguments.1 as? Value {
                    rValue = "%\(variable.name)"
                    let rPointer = "%\(count())"
                    code += "\(rPointer) = load \(workingType), \(workingType)* \(rValue)\n"
                    rValue = rPointer
                }
                else {
                    (rCode, rValue) = getExpressionResult(arguments.1)
                    rCode.map { code += "\($0)\n" }
                }
                
                let result = "%\(count())"
                code += "\(result) = \(instr) \(workingType) \(lValue), \(rValue)"
                
                return (code, result)

            default: break
            }
        }
        return nil
    }
}

func instruction(for operation: String, type: Type) -> String {
    var i = ""
    
    let int = type is IntType || type is PointerType
    let sgn = (type as? IntType)?.isSigned ?? false
    let flt = type is FloatType
    
    switch operation {
    case "*": i = int ? "mul" : (flt ? "fmul" : "")
    case "+": i = int ? "add" : (flt ? "fadd" : "")
    case "-": i = int ? "sub" : (flt ? "fsub" : "")
    case "/": i = int ? (sgn ? "sdiv" : "udiv") : (flt ? "fdiv" : "")
    case "%": i = int ? (sgn ? "srem" : "urem") : (flt ? "frem" : "")

    case "==": i = int ? "icmp eq" : ""
    case "!=": i = int ? "icmp ne" : ""
    
    case ">": i = int ? (sgn ?  "icmp sgt" : "icmp ugt") : ""
    case ">=": i = int ? (sgn ? "icmp sge" : "icmp uge") : ""
    case "<": i = int ? (sgn ?  "icmp slt" : "icmp ult") : ""
    case "<=": i = int ? (sgn ? "icmp sle" : "icmp ule") : ""

    default: break
    }
    
    if i != "" { return i }
    report("IRGen Error: \(operation) is not yet supported for '\(type)'.")
}
