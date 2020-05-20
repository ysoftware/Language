//
//  BinaryOperators.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

enum Operator {
    
    case assign
    
    // comparison
    case equal
    case notEqual
    case unsignedGreaterThan
    case unsignedGreaterOrEqual
    case unsignedLessThan
    case unsignedLessOrEqual
    case signedGreaterThan
    case signedGreaterOrEqual
    case signedLessThan
    case signedLessOrEqual
    
    // arithmetic
    case add
    case sub
    case mul
}

extension Operator {
    
    /// name of the instruction for integer types
    var int: String {
        switch self {
        case .add:                    return "add"
        case .sub:                    return "sub"
        case .mul:                    return "mul"
        
        case .equal:                  return "icmp eq"
        case .notEqual:               return "icmp ne"
        case .unsignedGreaterThan:    return "icmp ugt"
        case .unsignedGreaterOrEqual: return "icmp uge"
        case .unsignedLessThan:       return "icmp ult"
        case .unsignedLessOrEqual:    return "icmp ule"
        case .signedGreaterThan:      return "icmp sgt"
        case .signedGreaterOrEqual:   return "icmp sge"
        case .signedLessThan:         return "icmp slt"
        case .signedLessOrEqual:      return "icmp sle"
        default: report("Float does not support this instruction: \(self)")
        }
    }
    
    /// name of the instruction for floating-point types
    var float: String {
        switch self {
        case .add:                    return "fadd"
        case .sub:                    return "fsub"
        case .mul:                    return "fmul"
        default: report("Float does not support this instruction: \(self)")
        }
    }
}
