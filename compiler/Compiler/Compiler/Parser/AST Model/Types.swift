//
//  Types.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Type: CustomDebugStringConvertible {
    
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

    // @Todo: this is a mess
    /// returns the updated base type 
    func updateSubtypes(with block: (Type)->Type) -> Type {
        if let pointer = self as? PointerType {
            pointer.pointeeType = block(pointer.pointeeType)
            _ = pointer.pointeeType.updateSubtypes(with: block)
        }
        else if let structType = self as? StructureType {
            for i in 0..<structType.solidTypes.count {
                structType.solidTypes[i] = block(structType.solidTypes[i])
                _ = structType.solidTypes[i].updateSubtypes(with: block)
            }
        }
        else if let arrayType = self as? ArrayType {
            arrayType.elementType = block(arrayType.elementType)
            _ = arrayType.elementType.updateSubtypes(with: block)
        }
        return block(self)
    }
}

class IntType: Type, Equatable {
    
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

class FloatType: Type, Equatable {

    let size: Int
    
    internal init(size: Int = 32) {
        self.size = size
    }
    
    static func == (lhs: FloatType, rhs: FloatType) -> Bool {
        lhs.size == rhs.size
    }
}

class PointerType: Type, Equatable {
    
    var pointeeType: Type
    
    internal init(pointeeType: Type) {
        self.pointeeType = pointeeType
    }
    
    static func == (lhs: PointerType, rhs: PointerType) -> Bool {
        lhs.pointeeType.equals(to: rhs.pointeeType)
    }
}

class ArrayType: Type, Equatable {
    
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

class UnresolvedType: Type {
    
}

class StructureType: Type, Equatable {
    
    let name: String
    var solidTypes: [Type]

    internal init(name: String, solidTypes: [Type] = []) {
        self.name = name
        self.solidTypes = solidTypes
    }
    
    static func == (lhs: StructureType, rhs: StructureType) -> Bool {
        lhs.name == rhs.name
    }
}

class AliasType: Type {

    let name: String

    internal init(name: String) {
        self.name = name
    }
}

class VoidType: Type { }
class AnyType: Type { }

extension Type {
    
    func equals(to value: Type) -> Bool {
        switch (self, value) {
        case (let a as IntType, let b as IntType): return a == b
        case (let a as FloatType, let b as FloatType): return a == b
        case (let a as ArrayType, let b as ArrayType): return a == b
        case (let a as StructureType, let b as StructureType): return a == b
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
     
    /// Always returns`custom types` as `unresolved`
    static func named(_ identifier: String) -> Type {
        switch identifier {
        case "Int": return .int
        case "Bool": return .bool
        case "Int8": return .int8
        case "Int16": return .int16
        case "Int32": return .int32
        case "Int64": return .int64
        case "Int128": return IntType(size: 128)

        case "Float": return .float
        case "Float16": return .half
        case "Float32": return .float
        case "Float64": return .double
        case "Float128": return FloatType(size: 128)

        case "String": return PointerType(pointeeType: .int8)
        case "Void": return .void
        case "Any": return .any

        default:
            if identifier.hasSuffix("*") {
                let name = String(identifier[..<identifier.endIndex(offsetBy: -1)])
                return PointerType(pointeeType: named(name))
            }
            return StructureType(name: identifier)
        }
    }

    static let half = FloatType(size: 16)
    static let float = FloatType()
    static let double = FloatType(size: 64)
    static let int = IntType()
    static let bool = IntType(size: 1)
    static let int8 = IntType(size: 8)
    static let int16 = IntType(size: 16)
    static let int32 = IntType(size: 32)
    static let int64 = IntType(size: 64)
    static let string = PointerType(pointeeType: Type.int8)
    static let void = VoidType()
    static let any = AnyType()
    static let unresolved = UnresolvedType()
    
    static func `struct`(_ name: String) -> StructureType {
        StructureType(name: name)
    }
    
    static func pointer(_ type: Type) -> PointerType {
        PointerType(pointeeType: type)
    }
}

extension Array where Element: Type {
    
    func contains(_ type: Type) -> Bool {
        for s in self {
            if s.equals(to: type) { return true }
        }
        return false
    }
    
    func equals(to array: [Type]) -> Bool {
        guard count == array.count else { return false }
        for i in 0..<count {
            if !self[i].equals(to: array[i]) { return false }
        }
        return true
    }
}
