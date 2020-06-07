//
//  Operations.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 06.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

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

func returnType(of operation: String, arg: Type) -> Type {
    switch operation {
    // MARK: - Expressions
    case "*", "/", "%":   return arg
    case "+", "-":        return arg
    case "<<", ">>":      return arg
    // equality
    case "<", ">":        return .bool
    case "==", "!=":      return .bool
    // boolean
    case "&":             return arg
    case "^":             return arg
    case "|":             return arg
    case "&&":            return .bool
    case "||":            return .bool
        
    // MARK: - Not expressions
        
    default: fatalError()
    }
}

func precedence(of operation: String) -> Int? {
    switch operation {
    // MARK: - Expressions
    case "*", "/", "%":   return Precedence.multiplication
    case "+", "-":        return Precedence.addition
    case "<<", ">>":      return Precedence.bitwiseShift
    // equality
    case "<", ">":        return Precedence.comparison
    case "==", "!=":      return Precedence.equality
    // boolean
    case "&":             return Precedence.bitOr
    case "^":             return Precedence.bitXor
    case "|":             return Precedence.bitOr
    case "&&":            return Precedence.logicAnd
    case "||":            return Precedence.logicOr
        
    // MARK: - Not expressions
        
    default: fatalError()
    }
}

