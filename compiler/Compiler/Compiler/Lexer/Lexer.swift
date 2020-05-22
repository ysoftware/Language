//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

// @Todo: file name and line number

struct Lexer {
    
    let symbols: [Character] = [ ":", "+", "-", "*", "/", "=", ">", "<", ".", "#", "!", "&", "{", "}", "(", ")",  "[", "]"]
    let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
    let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
    let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
    
    // @Speed: this is very slow
    func analyze(_ string: String) -> [Token] {
        var tokens: [Token] = []
        var i = 0
        var char = string[string.index(string.startIndex, offsetBy: i)]
        
        func nextChar() {
            i += 1
            guard string.count > i else { return }
            char = string[string.index(string.startIndex, offsetBy: i)]
        }
        
        
        // checks if next char exists and matches, then eats it if it does
        // if not, does nothing and returns nil
        func expect(_ compare: (Character)->Bool) -> Character? {
            let nextIndex = i + 1
            guard string.count > nextIndex else { return nil }
            let char = string[string.index(string.startIndex, offsetBy: nextIndex)]
            if compare(char) {
                i += 1 // eat
                return char
            }
            return nil
        }
        
        
        
        loop: while i < string.count {
            
            switch char {
                
                // @Todo: comment, folded comment
                // @Todo: string literal
                
            case ";",  ",": // @Note: ignore \n for now, let's go with ;
                tokens.append(.separator(symbol: String(char)))
                
            case lowercaseRange, uppercaseRange, "_":
                var value = String(char)
                
                while let next = expect({
                    lowercaseRange.contains($0)
                        || uppercaseRange.contains($0)
                        || numberRange.contains($0)
                        || $0 == "_" }) {
                            value.append(next)
                }
                
                if keywords.contains(value) {
                    tokens.append(.keyword(name: value))
                }
                else {
                    tokens.append(.identifier(name: value))
                }
                
            case numberRange, ".":
                var value = String(char)
                
                // @Todo: handle - for negative literals
                
                // @Todo: we don't expect a number literal to continue
                // after first '0', except when it's a hex literal like 0xffff
                // 0 makes sense, 0124 doesn't
                
                while let next = expect({
                    numberRange.contains($0)
                        || ($0 == "e" && !value.contains("e"))
                        || ($0 == "." && !value.contains("."))}) {
                            value.append(next)
                }
                
                if value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    tokens.append(.literal(value: .float(value: Float(value)!)))
                }
                else {
                    tokens.append(.literal(value: .int(value: Int(value)!)))
                }
                
            case _ where symbols.contains(char):
                
                // .., ...
                if char == ".", let _ = expect({ $0 == "." }) {
                    if let _ = expect({ $0 == "." }) {
                        tokens.append(.punctuator(character: "..."))
                        break
                    }
                    tokens.append(.punctuator(character: ".."))
                    break
                }
                
                if char == "-", let _ = expect({ $0 == ">" }) {
                    tokens.append(.punctuator(character: "->"))
                    break
                }
                
                // fallback
                tokens.append(.punctuator(character: String(char)))
                
                // @Todo: &&, ||, >=, <=, ==, !=, +=, -=, *=, /=, %=, |=,
                // @Todo: >>, <<, >>=, <<=
                // @Todo: ^=
                // @Todo:
                // @Todo: #[.]  for directive
                // @Todo: ...   for varargs
                // @Todo: ..    for ranges
                // @Todo: ->    for function return type
                
                
            default:
                break
            }
            nextChar()
        }
        
        return tokens
    }
}


