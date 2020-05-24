//
//  LexerTestCases.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension LexerTest {
    
    func testCursors() {
        let code = "hello, world\n1"
        
        printResultCase(code, Lexer.analyze(code), [
            Token(.identifier(value: "hello"),
                  start: Cursor(lineNumber: 1, character: 0),
                  end: Cursor(lineNumber: 1, character: 4)),
            Token(.separator(value: ","),
                  start: Cursor(lineNumber: 1, character: 4),
                  end: Cursor(lineNumber: 1, character: 5)),
            Token(.identifier(value: "world"),
                  start: Cursor(lineNumber: 1, character: 6),
                  end: Cursor(lineNumber: 1, character: 11)),
            Token(.literal(value: .int(value: 1)),
                  start: Cursor(lineNumber: 2, character: 0),
                  end: Cursor(lineNumber: 2, character: 1)),
        ])
    }
        
    func testMultilineStringLiteralFail3() {
        let code = """
\"\"\"
Hello
"""
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedEndOfFile))
    }
    
    func testMultilineStringLiteralFail2() {
        let code = """
\"\"\"
Hello
"\"\"\"a
"""
        printErrorCase(code, Lexer.analyze(code), LexerError(.newlineExpectedAfterMultilineStringLiteral))
    }
    
    func testMultilineStringLiteralFail() {
        let code = """
\"\"\"
Hello"\"\"\"
"""
        printErrorCase(code, Lexer.analyze(code), LexerError(.newlineExpectedAfterMultilineStringLiteral))
    }
    
    func testMultilineStringLiteral() {
        let code = """
\"\"\"


\"\"\"

\"\"\"

Test
"It"
\"\"\"
"""
        printResultCase(code, Lexer.analyze(code), asTokens([
            .literal(value: .string(value: "\n")),
            .literal(value: .string(value: "\nTest\n\"It\""))
        ]))
    }
    
    func testStringLiteralFail() {
        let code = """
"Hello sailor

"""
        printErrorCase(code, Lexer.analyze(code), LexerError(.newLineInStringLiteral))
    }
    
    func testStingLiteralFail3() {
        let code = "\"No end"
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedEndOfFile))
    }
    
    func testStingLiteralFail2() {
        let code = "\""
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedEndOfFile))
    }
    
    func testStringLiteral() {
        let code = """
"Hello, Sailor!" ""
"""
        printResultCase(code, Lexer.analyze(code), asTokens([
            .literal(value: .string(value: "Hello, Sailor!")),
            .literal(value: .string(value: ""))
        ]))
    }
    
    func testDirectiveFail() {
        let code = "hello #"
        printErrorCase(code, Lexer.analyze(code), LexerError(.emptyDirectiveName))
    }
    
    func testDirectiveFail2() {
        let code = "hello # hello"
        printErrorCase(code, Lexer.analyze(code), LexerError(.emptyDirectiveName))
    }
    
    func testDirectiveFail3() {
        let code = "hello #123"
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedDirectiveName))
    }
    
    func testDirective() {
        let code = "id: Int #foreign #_internal"
        
        printResultCase(code, Lexer.analyze(code), asTokens([
            .identifier(value: "id"),
            .punctuator(value: ":"),
            .identifier(value: "Int"),
            .directive(value: "foreign"),
            .directive(value: "_internal")
        ]))
    }
    
    func testComments() {
        let code = """
1 / 2
hello // this is a comment
violin /* this is another comment */ hello
maker /* this is a
/* folded */
multiline comment */
/* 1 */ goodbye

/*
bye
"""
        
        printResultCase(code, Lexer.analyze(code), asTokens([
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
            .comment(value: "bye"), // comment to the end of the file
        ]))
    }
    
    func testNumbersFail() {
        let code = "1.1.1"
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedDotInFloatLiteral))
    }
    
    func testNumbersFail2() {
        let code = "10.134e12e37"
        printErrorCase(code, Lexer.analyze(code), LexerError(.unexpectedEInFloatLiteral))
    }
    
    func testNumbers() {
        let code = "1 -123 17.e2 1.1724 0 011 11. .11 -0"
        
        printResultCase(code, Lexer.analyze(code), asTokens([
            .literal(value: .int(value: 1)),
            .literal(value: .int(value: -123)),
            .literal(value: .float(value: Float("17.e2")!)),
            .literal(value: .float(value: Float(1.1724))),
            .literal(value: .int(value: 0)),
            .literal(value: .int(value: 011)),
            .literal(value: .float(value: Float(11))),
            .literal(value: .float(value: Float(0.11))),
            .literal(value: .int(value: Int(-0))),
        ]))
    }
    
    func testFunctionDeclaration() {
        let code = "func main(string: String) -> Int32 { }"
        
        printResultCase(code, Lexer.analyze(code), asTokens([
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
        ]))
    }
    
    func testBrackets() {
        let code = "I[aZ]a(saw)_d"
        
        printResultCase(code, Lexer.analyze(code), asTokens([
            .identifier(value: "I"),
            .punctuator(value: "["),
            .identifier(value: "aZ"),
            .punctuator(value: "]"),
            .identifier(value: "a"),
            .punctuator(value: "("),
            .identifier(value: "saw"),
            .punctuator(value: ")"),
            .identifier(value: "_d")
        ]))
    }
    
    func testVarargsRangeSpecialFloat() {
        let code = "Int32, ..., .1234, A..z"
        
        printResultCase(code, Lexer.analyze(code), asTokens([
            .identifier(value: "Int32"),
            .separator(value: ","),
            .punctuator(value: "..."),
            .separator(value: ","),
            .literal(value: .float(value: 0.1234)),
            .separator(value: ","),
            .identifier(value: "A"),
            .operator(value: ".."),
            .identifier(value: "z"),
        ]))
    }
}
