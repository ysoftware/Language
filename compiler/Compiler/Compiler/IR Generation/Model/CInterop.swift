//
//  CInterop.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 18.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

/// Переводит строку из "Something\n" в "Something\0A"
/// удаляет знаки, запрещенные внутри кода LLVM IR
func getCString(from value: String) -> String? {
    // @Todo: maybe I can convert any other encoding to cString
    // I'm passing ASCII right now, but maybe I should be passing utf8?
    guard let cString = value.cString(using: .ascii) else { return nil }
    
    func shouldConvertCharacter(_ char: CChar) -> Bool {
        return (0..<32).contains(char) || char == 127 || char == 92
    }
    
    let characters = cString.map { (char: CChar) -> String in
        if shouldConvertCharacter(char) {
            return String(format: "\\%02X", char)
        }
        return String(UnicodeScalar(UInt8(char)))
    }
    return characters.joined()
}
