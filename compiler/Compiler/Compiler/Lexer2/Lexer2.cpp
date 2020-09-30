//
//  Lexer2.cpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#include <stdlib.h>
#include "Lexer2.hpp"
#include "Lexer2Const.hpp"

Token *tokens;
int i = 0;
char character;

bool token_equals(Token *lhs, Token *rhs) {
    return false;
}

void token_append(Token *token, Cursor start, Cursor end) {

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

    Cursor cursor;
    cursor.lineNumber = 1;


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
