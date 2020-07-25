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
        case (int.typeName, int8.typeName),
             (int.typeName, int16.typeName),
             (int.typeName, int64.typeName),
             (int.typeName, half.typeName),
             (int.typeName, float.typeName),
             (int.typeName, double.typeName),
             (int.typeName, bool.typeName): return true
            
        // int64 >> float/64
        case (int64.typeName, half.typeName),
             (int64.typeName, float.typeName),
             (int64.typeName, double.typeName): return true
            
        // float >> double
        case (float.typeName, double.typeName): return true
            
        default:
            return false
        }
    }
}

func matchType(_ type: Type) -> String {
    switch type {
    case let a as IntType:
        return "i\(a.size)"
    case let a as PointerType:
        return a.pointeeType.equals(to: void) ? "i8*" :"\(matchType(a.pointeeType))*"
    case let a as FloatType:
        switch a.size {
        case 16: return "half"
        case 32: return "float"
        case 64: return "double"
        case 128: return "fp128"
        default: report("Unsupported floating point with \(a.size) bits")
        }
    case let a as ArrayType:
        if let size = a.size as? IntLiteral {
            return "[\(size.value) x \(matchType(a.elementType))]"
        } else {
            return matchType(pointer(a.elementType))
        }
    case is VoidType:
        return "void"
    case let structure as StructureType:
        if structure.id.contains("=") {
            report("Unsolidified type in IR Gen: \(structure).")
        }
        return "%\(structure.id)_struct"
    case is UnresolvedType:
        report("Unresolved type in IR Gen.")
    case let a as AliasType:
        report("Unsolidified type in IR Gen: \(a).")
    default:
        report("IRGen: Unsupported type \(type)")
    }
}
