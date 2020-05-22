//
//  LexerTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func lexer_testNumbersFail() {
    let code = "1.1.1"
    
    printLexerTestFail(
        code, Lexer.analyze(code),
        LexerError("Unexpected \".\" in the middle of a number literal"))
}

func lexer_testNumbers() {
    let code = "1 -123 17.e2 1.1724 0 011 11. .11"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .literal(value: .int(value: 1)),
        .literal(value: .int(value: -123)),
        .literal(value: .float(value: Float("17.e2")!)),
        .literal(value: .float(value: Float(1.1724))),
        .literal(value: .int(value: 0)),
        .literal(value: .int(value: 011)),
        .literal(value: .float(value: Float(11))),
        .literal(value: .float(value: Float(0.11))),
    ])
}

func lexer_testFunctionDeclaration() {
    let code = "func main(string: String) -> Int32 { }"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .keyword(name: "func"),
        .identifier(name: "main"),
        .punctuator(character: "("),
        .identifier(name: "string"),
        .punctuator(character: ":"),
        .identifier(name: "String"),
        .punctuator(character: ")"),
        .punctuator(character: "->"),
        .identifier(name: "Int32"),
        .punctuator(character: "{"),
        .punctuator(character: "}"),
    ])
}

func lexer_testBrackets() {
    let code = "I[aZ]a(saw)d"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .identifier(name: "I"),
        .punctuator(character: "["),
        .identifier(name: "aZ"),
        .punctuator(character: "]"),
        .identifier(name: "a"),
        .punctuator(character: "("),
        .identifier(name: "saw"),
        .punctuator(character: ")"),
        .identifier(name: "d")
    ])
}

func lexer_testVarargsRangeSpecialFloat() {
    let code = "Int32, ..., .1234, A..z"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .identifier(name: "Int32"),
        .separator(symbol: ","),
        .punctuator(character: "..."),
        .separator(symbol: ","),
        .literal(value: .float(value: 0.1234)),
        .separator(symbol: ","),
        .identifier(name: "A"),
        .punctuator(character: ".."),
        .identifier(name: "z"),
    ])
}
