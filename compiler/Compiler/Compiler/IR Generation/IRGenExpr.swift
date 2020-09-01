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
    
    func doAlloca(_ value: String, _ type: Type, countValue: String? = nil) -> String {
        let countString = countValue.map { ", i32 \($0)" } ?? ""
        return "\(value) = alloca \(matchType(type))\(countString)\n"
    }
    
    func doStore(from: String, into: String, valueType: Type) -> String {
        "store \(matchType(valueType)) \(from), \(matchType(valueType))* \(into)\n"
    }
    
    func doLoad(from: String, into: String, valueType: Type) -> String {
        "\(into) = load \(matchType(valueType)), \(matchType(valueType))* \(from)\n"
    }

    func doGEP(of: String, into: String, valueType: Type, inbounds: Bool = false, indexValues: [String]) -> String {
        let indicesStr = indexValues.map { "i32 \($0)" }.joined(separator: ", ")
        let inboundsString = inbounds ? "inbounds " : ""
        return "\(into) = getelementptr \(inboundsString)\(matchType(valueType)), \(matchType(valueType))* \(of), \(indicesStr)\n"
    }

    func doGEP(of: String, into: String, valueType: Type, indices: [Int]) -> String {
        let indicesStr = indices.map { "i32 \($0)" }.joined(separator: ", ")
        return "\(into) = getelementptr \(matchType(valueType)), \(matchType(valueType))* \(of), \(indicesStr)\n"
    }
}
