//
//  LexerConst.h
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 30.09.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

const char CHAR_NEWLINE = 10; // \n
const char CHAR_RETURN = 13; // \r
const char CHAR_TAB = 9; // \t
const char CHAR_BACKSLASH = 92; // backslash
const char CHAR_SLASH = 47; // /
const char CHAR_DOT = 46; // .
const char CHAR_SEMICOLON = 59; // ;
const char CHAR_COMMA = 44; // ,
const char CHAR_COLON = 58; // :
const char CHAR_QUOTE = 34; // "
const char CHAR_SPACE = 32; // ' '
const char CHAR_POUND = 35; // #
const char CHAR_UNDERSCORE = 95; // _
const char CHAR_DASH = 45; // -
const char CHAR_ACCENT = 96; // `
const char CHAR_ASTERISK = 42; // `
const char CHAR_ZERO = 42; // 0
const char CHAR_E = 101; // e
const char CHAR_N = 110; // n
const char CHAR_R = 114; // r
const char CHAR_T = 116; // t
const char CHAR_SLASH_ASTERISK[2] = {CHAR_SLASH, CHAR_ASTERISK};
const char CHAR_ASTERISK_SLASH[2] = {CHAR_ASTERISK, CHAR_SLASH};
const char CHAR_VOID[4] = {118, 111, 105, 100};
const char CHAR_NULL[4] = {110, 117, 108, 108};
const char CHAR_TRUE[4] = {116, 114, 117, 101};
const char CHAR_FALSE[5] = {102, 97, 108, 115, 101};

const char punctuators[11][3] = {
    {CHAR_DOT, CHAR_DOT, CHAR_DOT},
    {CHAR_DOT, 0, 0},
    {CHAR_COLON, 0, 0},
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

const char operators[28][3] = {
    //    ":=", "==", "!=", "<=", ">=", "&&", "||", ">", "<",
    //    "+=", "-=", "*=", "/=", "%=","^=", ">>", "<<", ">>=", "<<=",
    //    "-", "+", "/", "&", "*", "%", "..", "="
    {58, 61, 0}, {61, 61, 0}, {33, 61, 0}, {60, 61, 0}, {62, 61, 0}, {38, 38, 0}, {124, 124, 0}, {62, 0, 0}, {60, 0, 0},
    {43, 61, 0}, {45, 61, 0}, {42, 61, 0}, {47, 61, 0}, {37, 61, 0}, {94, 61, 0}, {62, 62, 0}, {60, 60, 0},
    {62, 62, 61}, {60, 60, 61}, {45, 0, 0}, {43, 0, 0}, {47, 0, 0}, {38, 0, 0}, {42, 0, 0},
    {37, 0, 0}, {46, 46, 0}, {61, 0, 0},
    {0, 0, 0}
};

const char separators[5] = {
    CHAR_NEWLINE, CHAR_SPACE, CHAR_SEMICOLON, CHAR_COMMA
};

const char TOKENRANGE_LOWERCASE_MIN = 97;
const char TOKENRANGE_LOWERCASE_MAX = 122;

const char TOKENRANGE_UPPERCASE_MIN = 65;
const char TOKENRANGE_UPPERCASE_MAX = 90;

const char TOKENRANGE_NUMBER_MIN = 48;
const char TOKENRANGE_NUMBER_MAX = 57;