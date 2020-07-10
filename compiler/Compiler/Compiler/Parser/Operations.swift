//
//  Operations.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 06.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension UnaryOperator {
    
    static let dereference = "*"
    static let memoryAddress = "&"
    static let negation = "-"
    static let cast = "cast"
}

// with precedence level
enum Precedence {
    
    // = 1  Function call, scope, array/member access
    // = 2  sizeof, cast, unary operators
    // = 13 Conditional expression (ternary)
    // = 14 Assignment operators (right to left)
    // = 15 Comma operator

    static let none                 = 0
    
    static let multiplication = 12 // 3
    static let addition       = 11 // 4
    static let bitwiseShift   = 10 // 5
    
    static let comparison     = 9  // 6
    static let equality       = 8  // 7
    
    static let bitAnd         = 7  // 8
    static let bitXor         = 6  // 9
    static let bitOr          = 5  // 10
    static let logicAnd       = 4  // 11
    static let logicOr        = 3  // 12
}

func precedence(of operation: String) -> Int? {
    switch operation {
    // math
    case "*", "/", "%":   return Precedence.multiplication
    case "+", "-":        return Precedence.addition
    case "<<", ">>":      return Precedence.bitwiseShift
    // equality
    case "<", ">":        return Precedence.comparison
    case "<=", ">=":      return Precedence.comparison
    case "==", "!=":      return Precedence.equality
    // boolean
    case "&":             return Precedence.bitOr
    case "^":             return Precedence.bitXor
    case "|":             return Precedence.bitOr
    case "&&":            return Precedence.logicAnd
    case "||":            return Precedence.logicOr
        
    default: report("Operation \(operation) is not yet implemented.")
    }
}

func isAccepting(_ operation: String, argType: Type) -> Bool {
    let math: [Type] = [int, int8, int16, int32, int64, float, double, half]
    
    switch operation {
    // math
    case "*", "/", "%":   return math.contains(argType)
    case "+", "-":        return math.contains(argType)
    case "<<", ">>":      return math.contains(argType)
    // equality
    case "<", ">":        return math.contains(argType)
    case "<=", ">=":      return math.contains(argType)
    case "==", "!=":      return true
    // boolean
    case "&":             return argType.equals(to: bool)
    case "^":             return argType.equals(to: bool)
    case "|":             return argType.equals(to: bool)
    case "&&":            return argType.equals(to: bool)
    case "||":            return argType.equals(to: bool)
    
    default: report("Operation \(operation) is not yet implemented.")
    }
}
