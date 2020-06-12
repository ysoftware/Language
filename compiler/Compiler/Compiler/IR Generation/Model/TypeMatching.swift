//
//  TypeMatching.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension LiteralExpr {

    func isCompliable(with type: Type) -> Bool {
        return exprType.isCompatible(with: type)
    }
}

extension Type {
    
    // @Todo figure out when we will need 'loss of data' checking when converting types
    
    // @Todo deal with the type system
    // it's a mess right now
    
    /// returns true if self can be converted to the given type
    func isCompatible(with type: Type) -> Bool {
        (self is IntType && type is IntType) || (self is FloatType && type is FloatType)
    }
}

func matchType(_ type: Type) -> String {
    switch type {
    case let a as IntType: return "i\(a.size)"
    case let a as ArrayType: return "[\(a.size) x \(matchType(a.elementType))]"
    case let a as PointerType:
        if a.pointeeType.equals(to: .void) { return "i8*" }
        return "\(matchType(a.pointeeType))*"
    case let a as FloatType:
        switch a.size {
        case 16: return "half"
        case 32: return "float"
        case 64: return "double"
        case 128: return "fp128"
        default: report("Unsupported floating point with \(a.size) bits")
        }
    case is VoidType: return "void"
    case is UnresolvedType: report("Unresolved type in IR Gen.")
    case is StructureType:
        report("Structures are not yet implemented.")
    default: report("Unsupported type \(type)")
    }
}
