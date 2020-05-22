//
//  Lexer.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

// @Todo: file name and line number

private extension String {
    
    func endIndex(offsetBy offset: Int) -> String.Index { index(endIndex, offsetBy: offset) }
    func startIndex(offsetBy offset: Int) -> String.Index { index(startIndex, offsetBy: offset) }
    subscript(index: Int) -> Character { self[startIndex(offsetBy: index)] }
}

struct Lexer {
    
    let symbols: [Character] = [ ":", "+", "-", "*", "/", "=", ">", "<", ".", "#", "!", "&", "{", "}", "(", ")",  "[", "]"]
    let lowercaseRange = ClosedRange<Character>(uncheckedBounds: ("a", "z"))
    let uppercaseRange = ClosedRange<Character>(uncheckedBounds: ("A", "Z"))
    let numberRange = ClosedRange<Character>(uncheckedBounds: ("0", "9"))
    
    // @Speed: this is very slow
    func analyze(_ string: String) -> [Token] {
        var tokens: [Token] = []
        var i = 0
        var char = string[i]
        
        func nextChar() {
            i += 1
            guard string.count > i else { return }
            char = string[i]
        }
        
        
        // checks if next char exists and matches, but does not eat it
        // func match(_ compare: (Character)->Bool) -> Bool {
        //
        // }
        
        // checks if next char exists and matches, then eats it if it does
        // if not, does nothing and returns nil
        func match(_ compare: (Character)->Bool) -> Character? {
            let nextIndex = i + 1
            guard string.count > nextIndex else { return nil }
            let char = string[nextIndex]
            if compare(char) {
                i += 1 // eat
                return char
            }
            return nil
        }
        
        // checks if one of the strings in the array
        // matches current and subsequent characters
        func match(oneOf array: [String]) -> String? {
            var leftValues = array
            var index = 0
            var query = String(char)
            
            while string.count > i + index {
                let filtered = leftValues.filter {
                    $0.count >= index && $0.starts(with: query)
                }
                
                if filtered.isEmpty {
                    let prevQuery = String(query[query.startIndex..<query.endIndex(offsetBy: -1)])
                    if leftValues.contains(prevQuery) {
                        i += prevQuery.count - 1
                        return prevQuery
                    }
                    return nil
                }
                
                leftValues = filtered
                if leftValues.count == 1, leftValues[0] == query {
                    i += query.count - 1
                    return query
                }
                
                index += 1
                guard string.count > i + index else { return nil }
                let nextChar = string[i + index]
                query += String(nextChar)
            }
            return nil
        }
        
//        // TEST
//        while string.count > i {
//            char = string[i]
//            if let found = expect(oneOf: ["..", "...", "."]) {
//                print("result:", found, "\n\n\n")
//            }
//            i += 1
//        }
//
//        return []
        
        
        
        
        loop: while i < string.count {
            
            switch char {
                
                // @Todo: comment, folded comment
                // @Todo: string literal
                
            case ";",  ",": // @Note: ignore \n for now, let's go with ;
                // SEPARATORS
                tokens.append(.separator(symbol: String(char)))
                
            case lowercaseRange, uppercaseRange, "_":
                // KEYWORDS / IDENTIFIERS
                var value = String(char)
                
                while let next = match({
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
                
            case numberRange, ".", "-":
                // NUMBER LITERALS
                var value = String(char)
                
                // @Todo: handle "-" for negative literals
                
                // @Todo: we don't expect a number literal to continue
                // after first '0', except when it's a hex literal like 0xffff
                // 0 makes sense, 0124 doesn't
                
                while let next = match({
                    numberRange.contains($0)
                        || ($0 == "e" && !value.contains("e"))
                        || ($0 == "." && !value.contains(".")) }) {
                            value.append(next)
                }
                
                if value == "-" || value.replacingOccurrences(of: ".", with: "").isEmpty {
                    fallthrough
                }
                else if value.contains("e") || value.contains(".") {
                    tokens.append(.literal(value: .float(value: Float(value)!)))
                }
                else {
                    tokens.append(.literal(value: .int(value: Int(value)!)))
                }
                
            case _ where symbols.contains(char):
                // PUNCTUATORS, OPERATORS
                
                let punctuators = ["->", "...", "[", "]", "(", ")", "{", "}", ":"]

                if let value = match(oneOf: punctuators) {
                    tokens.append(.punctuator(character: value))
                    break
                }
                
                let operators = ["..",
                                 "&&", "||", "!=", "==", "^=",
                                 ">>", "<<", ">>=", "<<=",
                                 "<=", ">=", "+=", "-=", "*=", "/=", "%="]
                
                if let value = match(oneOf: operators) {
                    tokens.append(.punctuator(character: value))
                    break
                }
                
                fallthrough
                
                // @Todo: #[.]  for directive
                
            default:
                break
            }
            nextChar()
        }
        
        return tokens
    }
}


