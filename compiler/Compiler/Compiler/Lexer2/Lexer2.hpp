//
//  Lexer2.hpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#include <stdio.h>
#include <stdbool.h>

enum TokenType {
    IDENTIFIER, PUNCTUATOR, DIRECTIVE, OPERATOR, COMMENT, SEPARATOR,
    NULLLITERAL, VOIDLITERAL, INTLITERAL, FLOATLITERAL, STRINGLITERAL, KEYWORD, ENDOFFILE
};
typedef enum TokenType TokenType;

enum Keyword {
    FUNC, BREAK, CONTINUE, FALLTHROUGH, WHILE, FOR, ENUM, STRUCT, DEFER, IF, ELSE, SWITCH, CASE,
    RETURN, CAST, SIZEOF, NEW, FREE
};
typedef enum Keyword Keyword;

struct Token {
    TokenType type;

    union {
        char *stringValue;
        int intValue;
        double doubleValue;
        bool boolValue;
        Keyword keyword;
    };
};
typedef struct Token Token;

bool token_equals(Token *lhs, Token *rhs);

struct Cursor {
    int lineNumber;
    int character;
};
typedef struct Cursor Cursor;

struct Output {
    int linesProcessed;
    Token *tokens;
};
typedef struct Output Output;

struct Lexer2 {
    char *fileName;
    char *characters;

    Output *output;
    Cursor cursor;
    int i;
    char c;
};
typedef struct Lexer2 Lexer2;

