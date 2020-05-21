//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate extension String {
    
    func at(_ index: Int) -> Character {
        self[self.index(startIndex, offsetBy: index)]
    }
    
    func safeAt(_ index: Int) -> Character? {
        guard count > index else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

struct Lexer {
    
    
    let letterRange = ClosedRange<Character>(uncheckedBounds: ("A", "z"))
    let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
    
    // @Speed: this is very slow
    func analyze(_ string: String) -> [Token] {
        
        var tokens: [Token] = []
        
        var i = 0
        while i < string.count {
            var char = string.at(i)
            
            switch char {
                
                // @Todo: comment, folded comment
                // @Todo: string literal
                
            case ";",  ",": // @Note: ignore \n for now, let's go with ;
                tokens.append(.separator(symbol: String(char)))
                
            case letterRange, "_":
                var tokenString = String(char)
                
                while i < string.count - 1 {
                    i += 1
                    char = string.at(i)
                    
                    guard letterRange.contains(char)
                        || numberRange.contains(char)
                        || char == "_"
                        else { i -= 1; break }
                    
                    tokenString.append(char)
                }
                
                if keywords.contains(tokenString) {
                    tokens.append(.keyword(name: tokenString))
                }
                else {
                    tokens.append(.identifier(name: tokenString))
                }
                
            case numberRange, ".":
                var value = String(char)
                
                // @Todo: handle - for negative literals
                
                // @Todo: we don't expect a number literal to continue
                // after first '0', except when it's a hex literal like 0xffff
                // 0 makes sense, 0124 doesn't
                
                while i < string.count {
                    i += 1
                    char = string.at(i)
                    
                    guard numberRange.contains(char)
                        || (char == "e" && !value.contains("e"))
                        || (char == "." && !value.contains("."))
                        else { i -= 1; break }
                    
                    value += String(char)
                }
                
                // if only dots
                if value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                
                if value.contains("e") || value.contains(".") {
                    tokens.append(.literal(value: .float(value: Float(value)!)))
                }
                else {
                    tokens.append(.literal(value: .int(value: Int(value)!)))
                }
                
            case ":", "+", "-", "*",
                 "/", "=", ">", "<",
                 ".", "#",
                 "!", "&", // "~",
            "{", "}", "(", ")",  "[", "]":
                
                let value = String(char)
                i += 1
                
                if value == ".", let secondDot = string.safeAt(i), secondDot == "." {
                    
                    if let thirdDot = string.safeAt(i+1), thirdDot == "." {
                        i += 1
                        tokens.append(.punctuator(character: "..."))
                        break
                    }
                    
                    tokens.append(.punctuator(character: ".."))
                    break
                }
                
                tokens.append(.punctuator(character: value))
                
                // @Todo: &&, ||, >=, <=, ==, !=, +=, -=, *=, /=, %=, |=,
                // @Todo: >>, <<, >>=, <<=
                // @Todo: (&= for ^= ?)
                // @Todo:
                // @Todo: #[.]  for directive
                // @Todo: ...   for varargs
                // @Todo: ..    for ranges
                // @Todo: ->    for function return type
                
                
            default:
                break
            }
            i += 1
        }
        
        return tokens
    }
}


