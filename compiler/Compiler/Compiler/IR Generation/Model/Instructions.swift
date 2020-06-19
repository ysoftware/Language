//
//  BinaryOperators.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//
//

func instruction(for operation: String, type: Type) -> String {
    var i = ""
    
    let int = type is IntType
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
