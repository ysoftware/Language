//
//  LexerConst.h
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 30.09.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#ifndef Lexer2Const_h
#define Lexer2Const_h

const int TOKEN_NEWLINE = 10; // \n
const int TOKEN_RETURN = 13; // \r
const int TOKEN_TAB = 9; // \t

const int TOKEN_BACKSLASH = 92; // backslash
const int TOKEN_SLASH = 47; // /
const int TOKEN_DOT = 46; // .
const int TOKEN_SEMICOLON = 59; // ;
const int TOKEN_COMMA = 44; // ,
const int TOKEN_COLON = 58; // :
const int TOKEN_QUOTE = 34; // "
const int TOKEN_SPACE = 32; // ' '
const int TOKEN_POUND = 35; // #
const int TOKEN_UNDERSCORE = 95; // _
const int TOKEN_DASH = 45; // -
const int TOKEN_ACCENT = 96; // `
const int TOKEN_ASTERISK = 42; // `
const int TOKEN_ZERO = 42; // 0
const int TOKEN_E = 101; // e
const int TOKEN_N = 110; // n
const int TOKEN_R = 114; // r
const int TOKEN_T = 116; // t

const int TOKEN_SLASH_ASTERISK[2] = {TOKEN_SLASH, TOKEN_ASTERISK};
const int TOKEN_ASTERISK_SLASH[2] = {TOKEN_ASTERISK, TOKEN_SLASH};
const int TOKEN_VOID[4] = {118, 111, 105, 100};
const int TOKEN_NULL[4] = {110, 117, 108, 108};
const int TOKEN_TRUE[4] = {116, 114, 117, 101};
const int TOKEN_FALSE[5] = {102, 97, 108, 115, 101};

const int punctuators[11][3] = {
    {TOKEN_DOT, TOKEN_DOT, TOKEN_DOT},
    {TOKEN_DOT, 0, 0},
    {TOKEN_COLON, 0, 0},
    // "(", ")", "{", "}", "[", "]", "->"
    {40, 0, 0},
    {41, 0, 0},
    {123, 0, 0},
    {125, 0, 0},
    {91, 0, 0},
    {93, 0, 0},
    {45, 62, 0},
    {0, 0, 0}
};

const int operators[28][3] = {
    //    ":=", "==", "!=", "<=", ">=", "&&", "||", ">", "<",
    //    "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<=",
    //    "-", "+", "/", "&", "*", "%", "..", "="
    {58, 61, 0}, {61, 61, 0}, {33, 61, 0}, {60, 61, 0}, {62, 61, 0}, {38, 38, 0}, {124, 124, 0}, {62, 0, 0}, {60, 0, 0},
    {43, 61, 0}, {45, 61, 0}, {42, 61, 0}, {47, 61, 0}, {37, 61, 0}, {94, 61, 0}, {62, 62, 0}, {60, 60, 0},
    {62, 62, 61}, {60, 60, 61}, {45, 0, 0}, {43, 0, 0}, {47, 0, 0}, {38, 0, 0}, {42, 0, 0},
    {37, 0, 0}, {46, 46, 0}, {61, 0, 0},
    {0, 0, 0}
};

const int separators[5] = {
    TOKEN_NEWLINE, TOKEN_SPACE, TOKEN_SEMICOLON, TOKEN_COMMA
};

const int TOKENRANGE_LOWERCASE_MIN = 97;
const int TOKENRANGE_LOWERCASE_MAX = 122;

const int TOKENRANGE_UPPERCASE_MIN = 65;
const int TOKENRANGE_UPPERCASE_MAX = 90;

const int TOKENRANGE_NUMBER_MIN = 48;
const int TOKENRANGE_NUMBER_MAX = 57;

#endif /* Lexer2Const_h */
