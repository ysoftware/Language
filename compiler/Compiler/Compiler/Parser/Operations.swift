//
//  Operations.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 06.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

// with precedence level
enum BinaryPrecedence: Int, Comparable {
    
    static func < (lhs: BinaryPrecedence, rhs: BinaryPrecedence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    // = 1  Function call, scope, array/member access
    // = 2  sizeof, cast, unary operators
    // = 13 Conditional expression (ternary)
    // = 14 Assignment operators (right to left)
    // = 15 Comma operator

    case none           = 0
    
    case multiplication = 12 // 3
    case addition       = 11 // 4
    case bitwiseShift   = 10 // 5
    
    case comparison     = 9  // 6
    case equality       = 8  // 7
    
    case bitAnd         = 7  // 8
    case bitXor         = 6  // 9
    case bitOr          = 5  // 10
    case logicAnd       = 4  // 11
    case logicOr        = 3  // 12
}


func precedence(of operation: String) -> BinaryPrecedence {
    switch operation {
    // MARK: - Expressions
    case "*", "/", "%":   return .multiplication
    case "+", "-":        return .addition
    case "<<", ">>":      return .bitwiseShift
    // equality
    case "<", ">":        return .comparison
    case "==", "!=":      return .equality
    // boolean
    case "&":             return .bitOr
    case "^":             return .bitXor
    case "|":             return .bitOr
    case "&&":            return .logicAnd
    case "||":            return .logicOr
        
    // MARK: - Not expressions
        
    default: fatalError("incorrect operation")
    }
}

