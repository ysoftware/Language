//
//  TypeMatching.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension LiteralExpr {

    func isConvertible(to type: Type) -> Bool {
        if self.exprType.equals(to: type) { return true }
        
        let isFinalized = (self as? IntLiteral)?.isFinalized ?? (self as? FloatLiteral)?.isFinalized ?? true
        guard !isFinalized, let selfType = self.exprType as? IntType else { return false }
        
        switch (selfType.typeName, type.typeName) {
        
        // int32 to any number
        case (Type.int.typeName, Type.int8.typeName),
             (Type.int.typeName, Type.int16.typeName),
             (Type.int.typeName, Type.int64.typeName),
             (Type.int.typeName, Type.half.typeName),
             (Type.int.typeName, Type.float.typeName),
             (Type.int.typeName, Type.double.typeName),
             (Type.int.typeName, Type.bool.typeName): return true
            
        // int64 >> float/64
        case (Type.int64.typeName, Type.half.typeName),
             (Type.int64.typeName, Type.float.typeName),
             (Type.int64.typeName, Type.double.typeName): return true
            
        // float >> double
        case (Type.float.typeName, Type.double.typeName): return true
            
        default:
            return false
        }
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
