//
//  Types.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

protocol Type: CustomDebugStringConvertible {

    var isResolved: Bool { get }
    var isGeneric: Bool { get }

    /// Type removing all top-level pointers
    /// `Int** -> Int`
    /// `Node<Int*>* -> Node<Int*>`
    func getValueType() -> Type
}

extension Type {

    func getValueType() -> Type {
        var type: Type = self
        while let ptr = type as? PointerType {
            type = ptr.pointeeType
        }
        return type
    }

    var debugDescription: String { typeName }

    var isResolved: Bool { !(self is UnresolvedType) }

    var isGeneric: Bool {
        if let pointer = self as? PointerType {
            return pointer.pointeeType.isGeneric
        }
        else if let structType = self as? StructureType {
            return !structType.solidTypes.isEmpty
        }
        else if let arrayType = self as? ArrayType {
            return arrayType.elementType.isGeneric
        }
        return false
    }

    /// returns the updated base type
    func updateSubtypes(with block: (Type) throws ->Type) rethrows -> Type {
        let type = self
        if var pointer = type as? PointerType {
            pointer.pointeeType = try block(pointer.pointeeType)
            pointer.pointeeType = try pointer.pointeeType.updateSubtypes(with: block)
            return pointer
        }
        else if var structType = self as? StructureType {
            for i in 0..<structType.solidTypes.count {
                structType.solidTypes[i] = try block(structType.solidTypes[i])
                structType.solidTypes[i] = try structType.solidTypes[i].updateSubtypes(with: block)
            }
            return structType
        }
        else if var arrayType = self as? ArrayType {
            arrayType.elementType = try block(arrayType.elementType)
            arrayType.elementType = try arrayType.elementType.updateSubtypes(with: block)
            return arrayType
        }
        return try block(self)
    }
}

struct IntType: Type, Equatable {
    
    let size: Int // @Todo: I can make this any bit width from 1 bit to (2^23)-1 (about 8 million)
    let isSigned: Bool // @Todo: LLVM: unsigned?
    
    internal init(size: Int = 32, isSigned: Bool = false) {
        self.size = size
        self.isSigned = isSigned
    }
    
    static func == (lhs: IntType, rhs: IntType) -> Bool {
        lhs.size == rhs.size && lhs.isSigned == rhs.isSigned
    }
}

struct FloatType: Type, Equatable {

    let size: Int
    
    internal init(size: Int = 32) {
        self.size = size
    }
    
    static func == (lhs: FloatType, rhs: FloatType) -> Bool {
        lhs.size == rhs.size
    }
}

struct PointerType: Type, Equatable {
    
    var pointeeType: Type
    
    internal init(pointeeType: Type) {
        self.pointeeType = pointeeType
    }
    
    static func == (lhs: PointerType, rhs: PointerType) -> Bool {
        lhs.pointeeType.equals(to: rhs.pointeeType)
    }
}

struct ArrayType: Type, Equatable {
    
    var elementType: Type
    let size: Int
    
    internal init(elementType: Type, size: Int) {
        self.elementType = elementType
        self.size = size
    }
    
    static func == (lhs: ArrayType, rhs: ArrayType) -> Bool {
        lhs.elementType.equals(to: rhs.elementType) && lhs.size == rhs.size
    }
}

struct UnresolvedType: Type {
    
}

struct StructureType: Type, Equatable {
    
    let name: String
    var solidTypes: [Type]

    internal init(name: String, solidTypes: [Type] = []) {
        self.name = name
        self.solidTypes = solidTypes
    }
    
    static func == (lhs: StructureType, rhs: StructureType) -> Bool {
        lhs.name == rhs.name && lhs.solidTypes.equals(toArray: rhs.solidTypes)
    }

    func isSameType(as type: StructureType) -> Bool {
        self.name == type.name
    }
}

struct AliasType: Type, Equatable {

    let name: String

    internal init(name: String) {
        self.name = name
    }

    static func == (lhs: AliasType, rhs: AliasType) -> Bool {
        lhs.name == rhs.name
    }
}

struct VoidType: Type { }
struct AnyType: Type { }

extension Type {
    
    func equals(to value: Type) -> Bool {
        switch (self, value) {
        case (let a as IntType, let b as IntType): return a == b
        case (let a as FloatType, let b as FloatType): return a == b
        case (let a as ArrayType, let b as ArrayType): return a == b
        case (let a as StructureType, let b as StructureType): return a == b
        case (let a as AliasType, let b as AliasType): return a == b
        case (is UnresolvedType, is UnresolvedType): return true
        case (is VoidType, is VoidType): return true

        case (let a as PointerType, let b as PointerType):
            return a.pointeeType.equals(to: b.pointeeType)
            
        case (_, is AnyType), (is AnyType, _): return true
        default: return false
        }
    }
    
    var typeName: String {
        switch self {
        case let a as IntType: return "Int\(a.size)"
        case let a as FloatType: return "Float\(a.size)"
        case let a as PointerType: return "\(a.pointeeType.typeName)*"
        case let a as ArrayType: return "[\(a.elementType.typeName)]"
        case is VoidType: return "Void"
        case let a as StructureType:
            var string = "\(a.name)"
            if a.isGeneric {
                string.append("<\(a.solidTypes.map(\.typeName).joined(separator: ", "))>")
            }
            return string
        case is UnresolvedType: return "[Unresolved]"
        case let a as AliasType: return "=\(a.name)"
        case is AnyType: return "Any"
        default: report("typeName: Unknown type.")
        }
    }
}

extension Array where Element == Type {
    
    func contains(_ type: Type) -> Bool {
        for s in self {
            if s.equals(to: type) { return true }
        }
        return false
    }

    func equals(toArray array: [Type]) -> Bool {
        guard count == array.count else { return false }
        for i in 0..<count {
            if !self[i].equals(to: array[i]) { return false }
        }
        return true
    }
}

// global variables

/// Always returns`custom types` as `unresolved`
func typeNamed(_ identifier: String) -> Type {
    switch identifier {
    case "Int": return int
    case "Bool": return bool
    case "Int8": return int8
    case "Int16": return int16
    case "Int32": return int32
    case "Int64": return int64
    case "Int128": return IntType(size: 128)

    case "Float": return float
    case "Float16": return half
    case "Float32": return float
    case "Float64": return double
    case "Float128": return FloatType(size: 128)

    case "String": return PointerType(pointeeType: int8)
    case "Void": return void
    case "Any": return any

    default:
        if identifier.hasSuffix("*") {
            let name = String(identifier[..<identifier.endIndex(offsetBy: -1)])
            return PointerType(pointeeType: typeNamed(name))
        }
        return StructureType(name: identifier)
    }
}

let half: Type = FloatType(size: 16)
let float: Type = FloatType()
let double: Type = FloatType(size: 64)
let int: Type = IntType()
let bool: Type = IntType(size: 1)
let int8: Type = IntType(size: 8)
let int16: Type = IntType(size: 16)
let int32: Type = IntType(size: 32)
let int64: Type = IntType(size: 64)
let string: Type = PointerType(pointeeType: int8)
let void: Type = VoidType()
let any: Type = AnyType()
let unresolved = UnresolvedType()

func structure(_ name: String, _ solid: [Type] = []) -> StructureType {
    StructureType(name: name, solidTypes: solid)
}

func alias(_ name: String) -> AliasType {
    AliasType(name: name)
}

func pointer(_ type: Type) -> PointerType {
    PointerType(pointeeType: type)
}
