//
//  Types.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class StructDeclaration: Statement {
    
    let name: String
    let members: [Value]
    
    internal init(name: String, members: [Value]) {
        self.name = name
        self.members = members
    }
}

indirect enum Type: Equatable {
    
    case resolved(name: String)
    case unresolved
    case predicted(Type)
    
    static func type(name: String) -> Type {
        return Type.resolved(name: name)
    }
    
    static func == (lhs: Type, rhs: Type) -> Bool {
        return false // @Todo
    }
    
    var name: String {
        if case let .resolved(name) = self {
            return name
        }
        report("Unresolved type \(self)")
    }
}

extension Type {
    
    func predicted(_ type: Type) -> Type {
        return .predicted(type)
    }
    
    static let float = float32
    static let int = int32
    static let bool = int1
    
    static let int1 = type(name: "Int1")
    static let int8 = type(name: "Int8")
    static let int16 = type(name: "Int16")
    static let int32 = type(name: "Int32")
    static let int64 = type(name: "Int64")
    
    static let uint8 = type(name: "UInt8")
    static let uint16 = type(name: "UInt16")
    static let uint32 = type(name: "UInt32")
    static let uint64 = type(name: "UInt64")
    
    static let float16 = type(name: "Float16")
    static let float32 = type(name: "Float32")
    static let float64 = type(name: "Float64")
    
    static let string = type(name: "String")
    static let void = type(name: "Void")
}
