//
//  BinaryOperators.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

enum Instruction: String {
    
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

func precedenceLevel(of operation: String) -> Int {
    switch operation {
    case "()", ".", "[]":
                        return 1  // Function call, scope, array/member access
                                  // sizeof, cast, unary operators
    case "*", "/", "%": return 3  // Multiplication, division, modulo
    case "+", "-":      return 4  // Addition and subtraction
    case "<<", ">>":    return 5  // Bitwise shift left and right
                                  // Comparisons: less-than and greater-than
                                  // Comparisons: equal and not equal
    case "&":           return 8  // Bitwise AND
    case "^":           return 9  // Bitwise exclusive OR (XOR)
    case "|":           return 10 // Bitwise inclusive (normal) OR
    case "&&":          return 11 // Logical AND
    case "||":          return 12 // Logical OR
    case "?", ":":      return 13 // Conditional expression (ternary)
        
    case "=", "+=", "-=", "*=", "/=", "%=", "|=":
                        return 14 // =   +=   -=   *=   /=   %=   &=   |=   ^=   <<=   >>= Assignment operators (right to left)
    case ",":           return 15 // Comma operator
    default:
        fatalError("incorrect operation")
    }
}

extension Instruction {
    
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
