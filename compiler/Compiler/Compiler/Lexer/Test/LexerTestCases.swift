//
//  LexerTestCases.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

fileprivate let eof = EOF()

extension LexerTest {

    func testInvalidIdentifierUnderscore() {
        let code = "_ := 1;"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.invalidIdentifierUnderscore))
    }
        
    func testBoolLiteral() {
        let code = "true false"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            TokenLiteral(value: .bool(value: true)),
            TokenLiteral(value: .bool(value: false)),
            eof
        ]))
    }
    
    func testCursors() {
        let code = "hello, world\n1\n\n123"
        
        printResultCase(code, Lexer(code).analyze(), [
            Token(Identifier(value: "hello"),
                  start: Cursor(lineNumber: 1, character: 0),
                  end: Cursor(lineNumber: 1, character: 4)),
            Token(Separator(value: ","),
                  start: Cursor(lineNumber: 1, character: 5),
                  end: Cursor(lineNumber: 1, character: 5)),
            Token(Identifier(value: "world"),
                  start: Cursor(lineNumber: 1, character: 7),
                  end: Cursor(lineNumber: 1, character: 11)),
            Token(TokenLiteral(value: .int(value: 1)),
                  start: Cursor(lineNumber: 2, character: 0),
                  end: Cursor(lineNumber: 2, character: 0)),
            Token(TokenLiteral(value: .int(value: 123)),
                  start: Cursor(lineNumber: 4, character: 0),
                  end: Cursor(lineNumber: 4, character: 2)),
            Token(eof)
        ])
    }
        
    func testMultilineStringLiteralFail3() {
        let code = """
\"\"\"
Hello
"""
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedEndOfFile))
    }
    
    func testMultilineStringLiteralFail2() {
        let code = """
\"\"\"
Hello
"\"\"\"a
"""
        printErrorCase(code, Lexer(code).analyze(), LexerError(.newlineExpectedAfterMultilineStringLiteral))
    }
    
    func testMultilineStringLiteralFail() {
        let code = """
\"\"\"
Hello"\"\"\"
"""
        printErrorCase(code, Lexer(code).analyze(), LexerError(.newlineExpectedAfterMultilineStringLiteral))
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
        printResultCase(code, Lexer(code).analyze(), asTokens([
            TokenLiteral(value: .string(value: "\n")),
            TokenLiteral(value: .string(value: "\nTest\n\"It\"")),
            eof
        ]))
    }
    
    func testStringLiteralFail() {
        let code = """
"Hello sailor

"""
        printErrorCase(code, Lexer(code).analyze(), LexerError(.newLineInStringLiteral))
    }
    
    func testStingLiteralFail3() {
        let code = "\"No end"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedEndOfFile))
    }
    
    func testStingLiteralFail2() {
        let code = "\""
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedEndOfFile))
    }
    
    func testStringLiteral() {
        let code = """
"Hello, Sailor!" ""
"""
        printResultCase(code, Lexer(code).analyze(), asTokens([
            TokenLiteral(value: .string(value: "Hello, Sailor!")),
            TokenLiteral(value: .string(value: "")),
            eof
        ]))
    }
    
    func testDirectiveFail() {
        let code = "hello #"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.emptyDirectiveName))
    }
    
    func testDirectiveFail2() {
        let code = "hello # hello"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.emptyDirectiveName))
    }
    
    func testDirectiveFail3() {
        let code = "hello #123"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedDirectiveName))
    }
    
    func testDirective() {
        let code = "id: Int #foreign #_internal"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            Identifier(value: "id"),
            Punctuator(value: ":"),
            Identifier(value: "Int"),
            Directive(value: "foreign"),
            Directive(value: "_internal"),
            eof
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
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            TokenLiteral(value: .int(value: 1)),
            Operator(value: "/"),
            TokenLiteral(value: .int(value: 2)),
            Identifier(value: "hello"),
            Comment(value: "this is a comment"),
            Identifier(value: "violin"),
            Comment(value: "this is another comment"),
            Identifier(value: "hello"),
            Identifier(value: "maker"),
            Comment(value: "this is a\n/* folded */\nmultiline comment"),
            Comment(value: "1"),
            Identifier(value: "goodbye"),
            Comment(value: "bye"), // comment to the end of the file
            eof
        ]))
    }
    
    func testNumbersFail() {
        let code = "1.1.1"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedDotInFloatLiteral))
    }
    
    func testNumbersFail2() {
        let code = "10.134e12e37"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedEInFloatLiteral))
    }
    
    func testNumbersFail3() {
        let code = "12-e23"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedMinusInNumberLiteral))
    }
    
    func testNumbersFail4() {
        // @Todo: this test fails
        // I need to find a way to consume() some sort of separation after a token
        // " ", ",", ";" or anything else. Not that it matters a lot, since
        // the parser will error on the expression in the test
        
        let code = "12a23"
        printErrorCase(code, Lexer(code).analyze(), LexerError(.unexpectedCharacter))
    }
    
    func testNumbers() {
        let code = "1 -123 17.e2 1.1724 0 011 11. .11 -0 1e-23 1_2_3_____"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            TokenLiteral(value: .int(value: 1)),
            TokenLiteral(value: .int(value: -123)),
            TokenLiteral(value: .float(value: 17.0e2)),
            TokenLiteral(value: .float(value: 1.1724)),
            TokenLiteral(value: .int(value: 0)),
            TokenLiteral(value: .int(value: 011)),
            TokenLiteral(value: .float(value: Float64(11))),
            TokenLiteral(value: .float(value: 0.11)),
            TokenLiteral(value: .int(value: -0)),
            TokenLiteral(value: .float(value: 1e-23)),
            TokenLiteral(value: .int(value: 123)),
            eof
        ]))
    }
    
    func testFunctionDeclaration() {
        let code = "func main(string: String) -> Int32 { }"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            Keyword.func,
            Identifier(value: "main"),
            Punctuator(value: "("),
            Identifier(value: "string"),
            Punctuator(value: ":"),
            Identifier(value: "String"),
            Punctuator(value: ")"),
            Punctuator(value: "->"),
            Identifier(value: "Int32"),
            Punctuator(value: "{"),
            Punctuator(value: "}"),
            eof
        ]))
    }
    
    func testBrackets() {
        let code = "I[aZ]a(saw)_d"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            Identifier(value: "I"),
            Punctuator(value: "["),
            Identifier(value: "aZ"),
            Punctuator(value: "]"),
            Identifier(value: "a"),
            Punctuator(value: "("),
            Identifier(value: "saw"),
            Punctuator(value: ")"),
            Identifier(value: "_d"),
            eof
        ]))
    }
    
    func testVarargsRangeSpecialFloat() {
        let code = "Int32, ..., .1234, A..z"
        
        printResultCase(code, Lexer(code).analyze(), asTokens([
            Identifier(value: "Int32"),
            Separator(value: ","),
            Punctuator(value: "..."),
            Separator(value: ","),
            TokenLiteral(value: .float(value: 0.1234)),
            Separator(value: ","),
            Identifier(value: "A"),
            Operator(value: ".."),
            Identifier(value: "z"),
            eof
        ]))
    }
}
