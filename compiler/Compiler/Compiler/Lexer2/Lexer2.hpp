//
//  Lexer2.hpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#include <stdio.h>
#include <stdbool.h>

// @Todo: align bytes of these structs

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

struct Cursor {
    int lineNumber;
    int character;
};
typedef struct Cursor Cursor;

struct Token {
    TokenType type;
    Cursor start;
    Cursor end;

    union {
        char *stringValue;
        int intValue;
        double doubleValue;
        bool boolValue;
        Keyword keyword;
    };
};
typedef struct Token Token;

struct Output {
    int linesProcessed;
    Token *tokens; // turn into a buffer
};
typedef struct Output Output;

struct Lexer2 {
    char *fileName; // managed by the caller
    char *characters; // managed by the caller

    Output *output;
    Cursor cursor;
    int i;
};
typedef struct Lexer2 Lexer2;



void advance_cursor_line(Cursor *cursor) {
    cursor->character = 0;
    cursor->lineNumber += 1;
}

void advance_cursor_characters(Cursor *cursor, int count) {
    cursor->character += count;
}

bool token_equals(Token *lhs, Token *rhs) {
    return false;
}
