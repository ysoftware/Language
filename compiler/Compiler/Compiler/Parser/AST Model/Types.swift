//
//  Types.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

indirect enum Type: Equatable, CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case .resolved(let name): return "\(name)"
        case .predicted(let type): return "\(type) [!]"
        case .unresolved(let name): return name.map { "\($0) [?]" } ?? "unresolved"
        }
    }
    
    case resolved(name: String)
    case unresolved(name: String?)
    case predicted(Type)
    
    static func == (lhs: Type, rhs: Type) -> Bool {
        switch (lhs, rhs) {
        case (.resolved(let v1), .resolved(let v2)): return v1 == v2
        case (.unresolved(let v1), .unresolved(let v2)): return v1 == v2
        case (.predicted(let v1), .predicted(let v2)): return v1 == v2
        default: return false
        }
    }
    
    var name: String {
        if case let .resolved(name) = self {
            return name
        }
        report("Unresolved type \(self)")
    }
}

extension Type {
    
    static let primitives = [
        "Int", "Int1", "Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16",
        "UInt32", "UInt64", "Float", "Float16", "Float32", "Float64", "String", "Void"
    ]
    
    static func isPrimitive(_ name: String) -> Bool {
        primitives.contains(name)
    }
    
    static func type(name: String) -> Type {
        return Type.resolved(name: name)
    }
    
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

