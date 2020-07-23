//
//  LexerConst.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 22.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

enum C {
    static let newline: CChar = 10 // \n
    static let `return`: CChar = 13 // \r
    static let tab: CChar = 9 // \t

    static let backslash: CChar = 92 // \
    static let slash: CChar = 47 // /
    static let dot: CChar = 46 // .
    static let semicolon: CChar = 59 // ;
    static let comma: CChar = 44 // ,
    static let colon: CChar = 58 // :
    static let quote: CChar = 34 // "
    static let space: CChar = 32 // ' '
    static let pound: CChar = 35 // #
    static let underscore: CChar = 95 // _
    static let dash: CChar = 45 // -
    static let accent: CChar = 96 // `
    static let asterisk: CChar = 42 // `
    static let zero: CChar = 42 // 0
    static let e: CChar = 101 // e
    static let n: CChar = 110 // n
    static let r: CChar = 114 // r
    static let t: CChar = 116 // t

    static let slashAsterisk: ConstantSizeArray<CChar> = [C.slash, C.asterisk]
    static let asteriskSlash: ConstantSizeArray<CChar> = [C.asterisk, C.slash]
    static let void: ConstantSizeArray<CChar> = [118, 111, 105, 100]
    static let null: ConstantSizeArray<CChar> = [110, 117, 108, 108]
    static let `true`: ConstantSizeArray<CChar> = [116, 114, 117, 101]
    static let `false`: ConstantSizeArray<CChar> = [102, 97, 108, 115, 101]

    static func string(from value: ConstantSizeArray<CChar>) -> String {
        value[value.count] = 0
        return String(cString: value.memory.baseAddress!)
    }

    static let punctuators: [ConstantSizeArray<CChar>] = [
        [C.dot, C.dot, C.dot], [C.dot], [C.colon],
        // "(", ")", "{", "}", "[", "]", "->"
        [40], [41], [123], [125], [91], [93], [45, 62]
    ]
    
    static let operators: [ConstantSizeArray<CChar>] = [
        //    ":=", "==", "!=", "<=", ">=", "&&", "||", ">", "<",
        //    "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<=",
        //    "-", "+", "/", "&", "*", "%", "..", "="
        [58, 61], [61, 61], [33, 61], [60, 61], [62, 61], [38, 38], [124, 124], [62], [60],
        [43, 61], [45, 61], [42, 61], [47, 61], [37, 61], [94, 61], [62, 62], [60, 60],
        [62, 62, 61], [60, 60, 61], [45], [43], [47], [38], [42], [37], [46, 46], [61]
    ]
    
    static let separators: [ConstantSizeArray<CChar>] = [
        [C.newline], [C.space], [C.semicolon], [C.comma], [0]
    ]
    
    static let lowercaseRange = ClosedRange<CChar>(uncheckedBounds: (97, 122))
    static let uppercaseRange = ClosedRange<CChar>(uncheckedBounds: (65, 90))
    static let numberRange = ClosedRange<CChar>(uncheckedBounds: (48, 57))
    
}
