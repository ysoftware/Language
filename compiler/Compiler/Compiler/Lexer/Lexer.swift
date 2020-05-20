//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

protocol LexerOutput: class {
    
    func lexer(_ instance: Lexer, didGenerateToken token: Token)
    func lexerFinished(_ instance: Lexer)
}

class Lexer {
    
    weak var output: LexerOutput?
    let letterRange = Range<Character>(uncheckedBounds: (lower: "A", upper: "z"))
    let numberRange = Range<Character>(uncheckedBounds: (lower: "0", upper: "9"))
    
    // @Speed: this is very slow
    func analyze(_ string: String) {
    
        var i = 0
        while i < string.count {
            var char: Character { string[string.index(string.startIndex, offsetBy: i)] }
         
            switch char {
            case "+", "-", "*", "/", "=", ">", "<":
                output?.lexer(self, didGenerateToken: .punctuator(character: String(char)))
                // @Todo: add ->, ==, += and others
                
            case ";", "\n":
                output?.lexer(self, didGenerateToken: .separator(symbol: String(char)))
                
            case letterRange, "_":
                var tokenString = String(char)
                i += 1
                
                while i < string.count {
                    if !letterRange.contains(char) && char != "_" { break }
                    tokenString.append(char)
                    i += 1
                }
                
                if keywords.contains(tokenString) {
                    output?.lexer(self, didGenerateToken: .keyword(name: tokenString))
                }
                else {
                    output?.lexer(self, didGenerateToken: .identifier(name: tokenString))
                }
                
            case numberRange:
                var value = String(char)
                i += 1
                
                while i < string.count {
                    if !numberRange.contains(char)
                        && char != "e"
                        && char != "." { break }
                    
                    value += String(char)
                    i += 1
                }
                
                if value.contains("e") || value.contains(".") {
                    output?.lexer(self, didGenerateToken: .literal(value: .float(value: Float(value)!)))
                }
                else {
                    output?.lexer(self, didGenerateToken: .literal(value: .int(value: Int(value)!)))
                }
                
            default:
                break
            }
            i += 1
        }
    }
}


