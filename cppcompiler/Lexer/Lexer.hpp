//
//  Lexer.hpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#pragma once
#include "LexerConst.hpp"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <iostream>

using namespace std;

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
    int line_number;
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
    int lines_processed;
    int tokens_count;
    Token *tokens;
};
typedef struct Output Output;

struct Lexer {
    char *fileName; // managed by the caller
    char *characters; // managed by the caller

    Output *output;
    Cursor cursor;
    int i;
};
typedef struct Lexer Lexer;

Cursor* copy_cursor(Cursor cursor) {
    Cursor *copy = new Cursor();
    copy->line_number = cursor.line_number;
    copy->character = cursor.character;
    return copy;
}

void advance_cursor_line(Cursor *cursor) {
    cursor->character = 0;
    cursor->line_number += 1;
}

void advance_cursor_characters(Cursor *cursor, int count) {
    cursor->character += count;
}

bool token_equals(Token *lhs, Token *rhs) {
    return false;
}

char* cursor_string(Cursor cursor) {
    char *output = (char*) malloc(10);
    sprintf(output, "%d:%d", cursor.line_number, cursor.character);
    return output;
}

void print_token(Token token) {
    switch (token.type) {
        case STRINGLITERAL: {
            cout << "Token: String Literal: \"" << token.stringValue << "\" (" 
                << cursor_string(token.start) << " - " << cursor_string(token.end) << ")" << endl;
        }

        // IDENTIFIER, PUNCTUATOR, DIRECTIVE, OPERATOR, COMMENT, SEPARATOR, NULLLITERAL, VOIDLITERAL, INTLITERAL, FLOATLITERAL, , KEYWORD, ENDOFFILE
        default: break;
    }
}

Output* lexer_analyze(char* string);