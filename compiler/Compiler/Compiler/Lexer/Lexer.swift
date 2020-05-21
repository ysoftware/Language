//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension String {
    
    func at(_ index: Int) -> Character {
        self[self.index(startIndex, offsetBy: index)]
    }
}

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
        while i < string.count - 1 {
            var char = string.at(i)
         
            switch char {
                
                // @Todo: comment, folded comment
                // @Todo: string literal
                
            case ":", "+", "-", "*",
                 "/", "=", ">", "<",
                 ".", "#",
                 "!", "&", // "~",
                 "{", "}", "(", ")",  "[", "]":
                
                output?.lexer(self, didGenerateToken: .punctuator(character: String(char)))
                
                // @Todo: &&, ||, >=, <=, ==, !=, +=, -=, *=, /=, %=, |=,
                // @Todo: >>, <<, >>=, <<=
                // @Todo: (&= for ^= ?)
                // @Todo:
                // @Todo: #[.]  for directive
                // @Todo: ...   for varargs
                // @Todo: ->    for function return type
                
            case ";",  ",": // @Note: ignore \n for now, let's go with ;
                output?.lexer(self, didGenerateToken: .separator(symbol: String(char)))
                
            case letterRange, "_":
                var tokenString = String(char)
                i += 1
                char = string.at(i)
                
                while i < string.count {
                    if !letterRange.contains(char)
                        && !numberRange.contains(char)
                        && char != "_" { i -= 1; break }
                    tokenString.append(char)
                    i += 1
                    char = string.at(i)
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
                char = string.at(i)
                
                // @Todo: handle - for negative literals
                
                // @Todo: we don't expect a number literal to continue
                // after first '0', except when it's a hex literal like 0xffff
                // 0 makes sense, 0124 doesn't
                
                while i < string.count {
                    if !numberRange.contains(char) && char != "e" && char != "." { i -= 1; break }
                    value += String(char)
                    i += 1
                    char = string.at(i)
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
        
        output?.lexerFinished(self)
    }
}


