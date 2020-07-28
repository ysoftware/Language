//
//  IRGenExpr.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 26.06.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension IR {
    
    func doBr(if condition: String, then: String, else elseBlock: String) -> String {
        "br \(condition), label \(then), label \(elseBlock)\n"
    }
    
    func doBr(_ label: String) -> String {
        "br label \(label)\n"
    }
    
    func doAlloca(_ value: String, _ type: Type) -> String {
        "\(value) = alloca \(matchType(type))\n"
    }
    
    func doStore(from: String, into: String, valueType: Type) -> String {
        "store \(matchType(valueType)) \(from), \(matchType(valueType))* \(into)\n"
    }
    
    func doLoad(from: String, into: String, valueType: Type) -> String {
        "\(into) = load \(matchType(valueType)), \(matchType(valueType))* \(from)\n"
    }
    
    func doGEP(of: String, into: String, valueType: Type, indices: [Int]) -> String {
        let indicesStr = indices.map { "i32 \($0)" }.joined(separator: ", ")
        return "\(into) = getelementptr \(matchType(valueType)), \(matchType(valueType))* \(of), \(indicesStr)\n"
    }
}
