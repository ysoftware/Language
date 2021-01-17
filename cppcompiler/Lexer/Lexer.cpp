//
//  Lexer.cpp
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

#include "Lexer.hpp"

Cursor *cursor;
int tokens_count;
Token *tokens;
int i = 0;
char character;
char* code;
unsigned long stringCount;

int vi = 0;
char* value;
void value_reset() {
    // @Todo: free previous, if not null
    value = new char[100]; // @Todo: dynamic buffer for long strings
    vi = 0; 
}
void value_append(char character) {
    value[vi] = character;
    vi += 1;
}

void advance(int count) {
    for (int w = 0; w < count; w++) {
        i += 1;
        if (character == CHAR_NEWLINE) {
            advance_cursor_line(cursor);
        } else {
            advance_cursor_characters(cursor, count);
        }
    }
}

bool next_char_count(int n) {
    for (int w = 0; w < n; w++) {
        advance(1);

        if (stringCount <= i) {
            return false;
        }
        character = code[i];
    }
    return true;
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
    return consume_next([query](char character) {
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

char* peek_next_count(int n) {
    auto nextIndex = i + n;
    if (stringCount <= nextIndex) { return NULL; }
    return &code[nextIndex];
}

char* peek_next() {
    return peek_next_count(1);
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

bool is_next_three_quotes_after(int n) {
    if (!(stringCount > i + 2 + n)) {
        return false;
    }
    return code[i+n] == CHAR_QUOTE && code[i+1+n] == CHAR_QUOTE && code[i+2+n] == CHAR_QUOTE;
}

void error(const char* message, Cursor start, Cursor end, int lineNumber) {
    cout << "error occured: " << message << "\n(context: L" << lineNumber << ") " << endl;
    exit(1);
}

Output* lexer_analyze(char* string) {

    // initialization
    cursor = new Cursor();
    tokens = new Token[1024];


    cursor->lineNumber = 1;

    code = string;
    stringCount = strlen(string);

    while (stringCount > i) {

        switch (string[i]) {
            case CHAR_QUOTE:
            {
                cout << "starting quote" << endl;
                auto start = cursor;

                // STRING LITERAL

                auto is_multiline = is_next_three_quotes_after(0);
                if (is_multiline) {
                    next_char_count(3);
                    if (!consume(CHAR_NEWLINE)) {
                        error("newlineExpectedBeforeMultilineStringLiteral", *cursor, *cursor, __LINE__);
                    }
                } else {
                    if (!next_char()) {
                        error("unexpectedEndOfFile", *cursor, *cursor, __LINE__);
                    }
                }

                value_reset();
                while (stringCount > i) {
                    // if char == C.newline { /* @Todo: wtf is this? */ }

                    if (character == CHAR_BACKSLASH) {
                        auto next = peek_next();
                        if (next == NULL) {
                            error("unexpectedEndOfFile", *cursor, *cursor, __LINE__);
                        }

                        switch (*next) {
                            case CHAR_ZERO: value_append(0); break;
                            case CHAR_N: value_append(CHAR_NEWLINE); break;
                            case CHAR_R: value_append(CHAR_RETURN); break;
                            case CHAR_T: value_append(CHAR_TAB); break;
                            case CHAR_BACKSLASH: value_append(CHAR_BACKSLASH); break;
                            case CHAR_QUOTE: value_append(CHAR_QUOTE); break;
                            default:
                                error("unexpectedCharacterToEscape", *cursor, *cursor, __LINE__);
                                break;
                        }

                        if (!next_char() || !next_char()) {
                            error("unexpectedEndOfFile", *cursor, *cursor, __LINE__);
                        }
                        continue;
                    }

                    if (is_multiline) {
                        if (peek_next() == NULL) {
                            error("unexpectedEndOfFile", *cursor, *cursor, __LINE__);
                        } else if (is_next_three_quotes_after(0)) {
                            error("newlineExpectedAfterMultilineStringLiteral", *cursor, *cursor, __LINE__);
                        } else if (character == CHAR_NEWLINE && is_next_three_quotes_after(1)) {
                            next_char_count(4);

                            auto next = peek_next();
                            if (*next != CHAR_NEWLINE && *next != CHAR_SEMICOLON) {
                                error("newlineExpectedAfterMultilineStringLiteral", *cursor, *cursor, __LINE__);
                            } else {
                                auto token = make_token(STRINGLITERAL);
                                token->stringValue = value; // @Todo: copy string from buffer
                                token_append(token, start, cursor);
                            }
                        }
                    } else {
                        if (consume(CHAR_QUOTE)) { // @Note: if consume(string: [C.quote]) {
                            auto token = make_token(STRINGLITERAL);
                            token->stringValue = value; // @Todo: copy string from buffer
                            token_append(token, start, cursor);
                            break;
                        } else if (*peek_next() == CHAR_NEWLINE) {
                            error("newLineInStringLiteral", *cursor, *cursor, __LINE__);
                        }
                    }

                    value_append(character);
                    if (!next_char()) {
                        error("unexpectedEndOfFile", *cursor, *cursor, __LINE__);
                    }
                }
                break;
            }
            case CHAR_SEMICOLON: {
                cout << "starting separator" << endl;
                break;
            }
            case CHAR_COMMA: {
                cout << "starting comma" << endl;
                token_append(make_token_separator(&character), cursor, cursor);
                break;
            }
            default: {
                cout << "break:" << string[i] << " " << (int)string[i] << endl;
                i += 1;
                break;
            }
        }
    }

    Output *output = new Output(); 
    output->tokens = tokens;
    output->tokens_count = tokens_count;
    output->lines_processed = cursor->lineNumber;
    return output;
}
