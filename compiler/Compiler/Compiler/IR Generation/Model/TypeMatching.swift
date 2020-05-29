//
//  TypeMatching.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func matchType(_ typeName: String) -> String {
    switch typeName {
    case "Int": return matchType(Type.int.name)
    case "Float": return matchType(Type.float.name)
    case "Int1": return "i1"
    case "Int8": return "i8"
    case "Int16": return "i16"
    case "Int32": return "i32"
    case "Int64": return "i64"
    case "UInt8": return "ui8"
    case "UInt16": return "ui16"
    case "UInt32": return "ui32"
    case "UInt64": return "ui64"
    case "Bool": return "bool"
    case "String": return "i8*"
    case "Array": return "array"
    case "Pointer": return "pointer"
    case "Void": return "void"
    default: report("Undefined type \(typeName)")
    }
}
