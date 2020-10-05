//
//  Lexer2.cpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "Lexer2.hpp"
#include "Lexer2Const.hpp"

Cursor *cursor;
int tokens_count;
Token *tokens;
int i = 0;
char character;

char* code;
unsigned long stringCount;

void advance(int count) {
    for (int w = 0; w < count; w++) {
        i += 1;
        if (character == TOKEN_NEWLINE) {
            advance_cursor_line(cursor);
        } else {
            advance_cursor_characters(cursor, count);
        }
    }
}

bool next_char_count(int n) {
    for (int w = 0; w < n; w++) {
        advance(1);
        if (stringCount > i) {
            return false;
        }
        character = code[i];
    }
    return false;
}

bool next_char() {
    return next_char_count(1);
}

bool consume(char query) {
    if (character == query) {
        next_char();
        return true;
    }
    return false;
}

template <typename T>
char* consume_next(T compare) {
    int nextIndex = i + 1;
    if (stringCount <= nextIndex) {
        return NULL;
    }
    auto character = &code[nextIndex];
    if (compare(*character)) { // @Todo: test
        advance(1);
        return character;
    }
    return NULL;
}

bool consume_next_char(char query) {
    return consume_next([query](auto character) {
        return character == query;
    }) != NULL;
}

bool consume_string(char *string) { // @Todo: test
    int index = 0;
    while (string[index] != 0 && stringCount > i + index) {
        if (code[i + index] == string[index]) {
            index += 1;
        } else {
            return false;
        }
    }
    next_char_count(index); // @Todo: test: nextChar(count-1)
    return true;
}

char* consume_one_of(char **array) { // @Todo: test
    int index = 0;
    while (array[index] != 0 && stringCount > i + index) {
        auto s = array[index];
        if (consume_string(s)) {
            return s;
        }
        index += 1;
    }
    return NULL;
}

char* peekNext(int n) {
    auto nextIndex = i + n;
    if (stringCount <= nextIndex) { return NULL; }
    return &code[nextIndex];
}

void token_append(Token *token, Cursor *start, Cursor *end) {
    token->start = *start;
    token->end = *end;
    tokens[tokens_count] = *token;
    tokens_count += 1;
}

Token* make_token(TokenType type) {
    Token *token = (Token*) malloc(sizeof(*token));
    token->type = type;
    return token;
}

Token* make_token_separator(char* string) {
    Token *token = make_token(SEPARATOR);
    token->stringValue = string;
    return token;
}

void lexer_analyze(char* string) {
    cursor->lineNumber = 1;

    code = string;
    stringCount = strlen(string);

    while (true) {
        switch (string[i]) {
            case TOKEN_QUOTE:
            {
                auto start = cursor;
                break;
            }
            case TOKEN_SEMICOLON:
            case TOKEN_COMMA:
            {
                token_append(make_token_separator(&character), cursor, cursor);
                break;
            }
            default:
                break;
        }
    }
}
