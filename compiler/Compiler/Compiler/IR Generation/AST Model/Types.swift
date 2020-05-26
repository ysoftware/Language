//
//  Types.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct StructDeclaration: Statement {
    
    let name: String
    let members: [(name: String, type: String)]
}

struct Type: Equatable {
    
    let name: String
}

extension Type {
    
    static let float = float32
    static let int = int32
    static let bool = int1
    
    static let int1 = Type(name: "Int1")
    static let int8 = Type(name: "Int8")
    static let int16 = Type(name: "Int16")
    static let int32 = Type(name: "Int32")
    static let int64 = Type(name: "Int64")
    
    static let uint8 = Type(name: "UInt8")
    static let uint16 = Type(name: "UInt16")
    static let uint32 = Type(name: "UInt32")
    static let uint64 = Type(name: "UInt64")
    
    static let float16 = Type(name: "Float16")
    static let float32 = Type(name: "Float32")
    static let float64 = Type(name: "Float64")
    
    static let string = Type(name: "String")
    static let void = Type(name: "Void")
}
