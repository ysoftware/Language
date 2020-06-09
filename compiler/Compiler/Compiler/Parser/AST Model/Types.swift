//
//  Types.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

indirect enum Type: Equatable, CustomDebugStringConvertible {
    
    var isInteger: Bool {
        self == Type.int || self == Type.int8 || self == Type.int16 || self == Type.int32 || self == Type.int64
            || self == Type.uint8 || self == Type.uint16 || self == Type.uint32 || self == Type.uint64
    }
    
    var isSigned: Bool {
        self == Type.int || self == Type.int8 || self == Type.int16 || self == Type.int32 || self == Type.int64
    }
    
    var isFloat: Bool {
        self == Type.float || self == Type.float16 || self == Type.float32 || self == Type.float64
    }
    
    var debugDescription: String {
        switch self {
        case .resolved(let name): return "\(name)"
        case .predicted(let type): return "\(type) [!]"
        case .unresolved(let name): return name.map { "\($0) [?]" } ?? "unresolved"
        }
    }
    
    case resolved(name: String)
    case unresolved(name: String?)
    case predicted(name: String) // @Todo I need to formalize what predicted is and decide if I need it
    
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
    
    static let signedIntegers = ["Int", "Int8", "Int16", "Int32", "Int64"]
    static let unsignedIntegers = ["UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
    static let floats = ["Float", "Float16", "Float32", "Float64"]
    static let integers = signedIntegers + unsignedIntegers
    static let primitives = ["String", "Void"] + integers + floats
    
    static func isPrimitive(_ name: String) -> Bool {
        primitives.contains(name)
    }
    
    static func type(name: String) -> Type {
        .resolved(name: name)
    }
    
    static let float = type(name: "Float")
    static let int = type(name: "Int")
    static let bool = type(name: "Bool")
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

