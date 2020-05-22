//
//  LexerTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func lexer_testMultilineStringLiteralFail2() {
    let code = """
\"\"\"
Hello
"\"\"\"a
"""
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.newlineExpectedAfterMultilineStringLiteral))
}

func lexer_testMultilineStringLiteralFail() {
    let code = """
\"\"\"
Hello"\"\"\"
"""
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.newlineExpectedAfterMultilineStringLiteral))
}

func lexer_testMultilineStringLiteral() {
    let code = """
\"\"\"


\"\"\"

\"\"\"

Hello, Sailor!
When is JAI out?
"I really like it"
\"\"\"
"""
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .literal(value: .string(value: "\n")),
        .literal(value: .string(value: "\nHello, Sailor!\nWhen is JAI out?\n\"I really like it\""))
    ])
}

func lexer_testStringLiteral() {
    let code = """
"Hello, Sailor!" ""
"""
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .literal(value: .string(value: "Hello, Sailor!")),
        .literal(value: .string(value: ""))
    ])
}

func lexer_testDirectiveFail() {
    let code = "hello #"
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.emptyDirectiveName))
}

func lexer_testDirectiveFail2() {
    let code = "hello # hello"
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.emptyDirectiveName))
}

func lexer_testDirectiveFail3() {
    let code = "hello #123"
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.unexpectedDirectiveName))
}

func lexer_testDirective() {
    let code = "id: Int #foreign #_internal"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .identifier(value: "id"),
        .punctuator(value: ":"),
        .identifier(value: "Int"),
        .directive(value: "foreign"),
        .directive(value: "_internal")
    ])
}

func lexer_testStringLiteralFail() {
    let code = """
"Hello sailor

"""
    
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.newLineInStringLiteral))
}

func lexer_testComments() {
    let code = """
1 / 2
hello // this is a comment
violin /* this is another comment */ hello
maker /* this is a
/* folded */
multiline comment */
/* 1 */ goodbye
"""
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .literal(value: .int(value: 1)),
        .operator(value: "/"),
        .literal(value: .int(value: 2)),
        .identifier(value: "hello"),
        .comment(value: "this is a comment"),
        .identifier(value: "violin"),
        .comment(value: "this is another comment"),
        .identifier(value: "hello"),
        .identifier(value: "maker"),
        .comment(value: "this is a\n/* folded */\nmultiline comment"),
        .comment(value: "1"),
        .identifier(value: "goodbye"),
    ])
}

func lexer_testNumbersFail() {
    let code = "1.1.1"
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.unexpectedDotInFloatLiteral))
}

func lexer_testNumbersFail2() {
    let code = "10.134e12e37"
    printLexerTestFail(code, Lexer.analyze(code), LexerError(.unexpectedEInFloatLiteral))
}

func lexer_testNumbers() {
    let code = "1 -123 17.e2 1.1724 0 011 11. .11 -0"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .literal(value: .int(value: 1)),
        .literal(value: .int(value: -123)),
        .literal(value: .float(value: Float("17.e2")!)),
        .literal(value: .float(value: Float(1.1724))),
        .literal(value: .int(value: 0)),
        .literal(value: .int(value: 011)),
        .literal(value: .float(value: Float(11))),
        .literal(value: .float(value: Float(0.11))),
        .literal(value: .int(value: Int(-0))),
    ])
}

func lexer_testFunctionDeclaration() {
    let code = "func main(string: String) -> Int32 { }"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .keyword(value: "func"),
        .identifier(value: "main"),
        .punctuator(value: "("),
        .identifier(value: "string"),
        .punctuator(value: ":"),
        .identifier(value: "String"),
        .punctuator(value: ")"),
        .punctuator(value: "->"),
        .identifier(value: "Int32"),
        .punctuator(value: "{"),
        .punctuator(value: "}"),
    ])
}

func lexer_testBrackets() {
    let code = "I[aZ]a(saw)d"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .identifier(value: "I"),
        .punctuator(value: "["),
        .identifier(value: "aZ"),
        .punctuator(value: "]"),
        .identifier(value: "a"),
        .punctuator(value: "("),
        .identifier(value: "saw"),
        .punctuator(value: ")"),
        .identifier(value: "d")
    ])
}

func lexer_testVarargsRangeSpecialFloat() {
    let code = "Int32, ..., .1234, A..z"
    
    printLexerTestResult(code, Lexer.analyze(code), [
        .identifier(value: "Int32"),
        .separator(value: ","),
        .punctuator(value: "..."),
        .separator(value: ","),
        .literal(value: .float(value: 0.1234)),
        .separator(value: ","),
        .identifier(value: "A"),
        .operator(value: ".."),
        .identifier(value: "z"),
    ])
}
