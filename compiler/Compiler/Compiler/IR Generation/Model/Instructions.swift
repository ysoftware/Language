//
//  BinaryOperators.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//
//
//enum Instruction: String {
//
//    case assign
//
//    // comparison
//    case equal
//    case notEqual
//    case unsignedGreaterThan
//    case unsignedGreaterOrEqual
//    case unsignedLessThan
//    case unsignedLessOrEqual
//    case signedGreaterThan
//    case signedGreaterOrEqual
//    case signedLessThan
//    case signedLessOrEqual
//
//    // arithmetic
//    case add
//    case sub
//    case mul
//}

func instruction(for operation: String, type: Type) -> String {
    let isI = type.isInteger
    let isF = type.isFloat
    
    switch operation {
    // MARK: - Expressions
    case "*": if isI { return "mul" } else if isF { return "fmul" }
    case "+": if isI { return "add" } else if isF { return "fadd" }
    case "-": if isI { return "sub" } else if isF { return "fsub" }
        
    case "==": if isI { return "icmp eq" }
    case "!=": if isI { return "icmp ne" }
        
        //    case "/":
        //    case "%":
        //
        //    case "<<", ">>":      return Precedence.bitwiseShift
        //    // equality
        //    case "<", ">":        return Precedence.comparison
        //    case "==", "!=":      return Precedence.equality
        //    // boolean
        //    case "&":             return Precedence.bitOr
        //    case "^":             return Precedence.bitXor
        //    case "|":             return Precedence.bitOr
        //    case "&&":            return Precedence.logicAnd
    //    case "||":            return Precedence.logicOr
    default: break
    }
    fatalError("IRGen Error: \(operation) is not yet supported for '\(type)'.")
}

//extension Instruction {
//
//    /// name of the instruction for integer types
//    var int: String {
//        switch self {
//        case .add:                    return "add"
//        case .sub:                    return "sub"
//        case .mul:                    return "mul"
//
//        case .equal:                  return "icmp eq"
//        case .notEqual:               return "icmp ne"
//        case .unsignedGreaterThan:    return "icmp ugt"
//        case .unsignedGreaterOrEqual: return "icmp uge"
//        case .unsignedLessThan:       return "icmp ult"
//        case .unsignedLessOrEqual:    return "icmp ule"
//        case .signedGreaterThan:      return "icmp sgt"
//        case .signedGreaterOrEqual:   return "icmp sge"
//        case .signedLessThan:         return "icmp slt"
//        case .signedLessOrEqual:      return "icmp sle"
//        default: report("Float does not support this instruction: \(self)")
//        }
//    }
//
//    /// name of the instruction for floating-point types
//    var float: String {
//        switch self {
//        case .add:                    return "fadd"
//        case .sub:                    return "fsub"
//        case .mul:                    return "fmul"
//        default: report("Float does not support this instruction: \(self)")
//        }
//    }
//}
