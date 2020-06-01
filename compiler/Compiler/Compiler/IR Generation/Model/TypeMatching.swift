//
//  TypeMatching.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension LiteralExpr {

    func isCompliable(with typeName: String) -> Bool {
        guard Type.isPrimitive(exprType.name) else { return false }
        return exprType.isCompatible(with: .resolved(name: typeName))
    }
}

extension Type {
    
    // @Todo figure out when we will need 'loss of data' checking when converting types
    
    // @Todo deal with the type system
    // it's a mess right now
    
    /// returns true if self can be converted to the given type
    func isCompatible(with type: Type) -> Bool {
        func bothContained(in array: [String]) -> Bool { array.contains(name) && array.contains(type.name) }
        return bothContained(in: Type.integers) || bothContained(in: Type.floats)
    }
}

func matchType(_ typeName: String) -> String {
    switch typeName {
    case "Int": return matchType(Type.int32.name)
    case "Bool": return "i1"
    case "Int8": return "i8"
    case "Int16": return "i16"
    case "Int32": return "i32"
    case "Int64": return "i64"
    case "UInt8": return "ui8"
    case "UInt16": return "ui16"
    case "UInt32": return "ui32"
    case "UInt64": return "ui64"
    case "Float": return matchType(Type.float32.name)
    case "String": return "i8*"
    case "Array": return "array"
    case "Pointer": return "pointer"
    case "Void": return "void"
    default: report("Undefined type \(typeName)")
    }
}
