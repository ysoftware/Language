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
    NULLLITERAL, VOIDLITERAL, INTLITERAL, FLOATLITERAL, BOOLLITERAL, STRINGLITERAL, KEYWORD, ENDOFFILE
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

bool only_contains_character(char* string, char character) {
    int i = 0;
    while (string[i] != 0) {
        if (string[i] != character) {
            return false;
        }
        i += 1;
    }
    return true;
}

bool is_in_range(char character, char min, char max) {
    return character >= min && character <= max;
}

char last_char_of(char *string) {
    int length = strlen(string);
    return string[length-1];
}

bool string_contains(char* string, char character) {
    int i = 0;
    while(true) {
        if (string[i] == character) {
            return true;
        }
        if (string[i] == 0) {
            break;
        }
        i += 1;
    }
    return false;
}

bool string_compare(char* first, char* second) {
    int i = 0;
    while(first[i] == second[i]) {
        if (first[i] == 0 && second[i] == 0) {
            return true;
        }
        i += 1;
    }
    return false;
}

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
            cout << "[String Literal \"" << token.stringValue << "\"";
            break;
        }
        case SEPARATOR: {
            cout << "[Separator " << token.stringValue;
            break;
        }
        case IDENTIFIER: {
            cout << "[Identifier " << token.stringValue;
            break;
        } 
        case DIRECTIVE: {
            cout << "[Directive " << token.stringValue;
            break;
        }
        case VOIDLITERAL: {
            cout << "[Void";
            break;
        }
        case BOOLLITERAL: {
            cout << "[Bool ";
            if (token.boolValue) { cout << "true"; } 
            else { cout << "false"; }
            break;
        }
        case ENDOFFILE: {
            cout << "[Token EOF";
            break;
        }
        case INTLITERAL: {
            cout << "[Literal " << token.intValue;
            break;
        }
        case FLOATLITERAL: {
            typedef std::numeric_limits< double > dbl;
            cout.precision(dbl::max_digits10);
            cout << "[Literal " << token.doubleValue;
            break;
        }

        // PUNCTUATOR, OPERATOR, COMMENT,
        // NULLLITERAL, VOIDLITERAL, INTLITERAL, FLOATLITERAL, BOOLLITERAL, STRINGLITERAL, 
        // KEYWORD, ENDOFFILE

        // IDENTIFIER, PUNCTUATOR, DIRECTIVE, OPERATOR, COMMENT, SEPARATOR, NULLLITERAL, VOIDLITERAL, INTLITERAL, FLOATLITERAL, , KEYWORD, ENDOFFILE
        default:
            cout << "[Not implemented: Type: " << token.type;
        break;
    }
    cout << " " << cursor_string(token.start) << " - " << cursor_string(token.end) << "]" << endl;
}

Output* lexer_analyze(char* string);