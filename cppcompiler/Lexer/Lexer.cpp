//
//  Lexer.cppc
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

int value_length = 0; // value length
char* value = (char*) malloc(1000); // @Todo: dynamic buffer for longer strings

char* get_value_in_range(int min, int max) {
    char* copy = new char[max-min];
    auto pointer = (char*) &value + min;
    strcpy(copy, pointer);
    return copy;
}

char* get_value() {
    char* copy = new char[value_length];
    strcpy(copy, value);
    return copy;
}

void value_reset() {
    memset(value, 0, value_length);
    value_length = 0;
}

void value_append(char character) {
    value[value_length] = character;
    value_length += 1;
}

int index_in_value_of(char character) {
    for (int i = 0; i < value_length; i++) {  
        if (value[i] == character) {
            return i;
        }
    }
    return -1;
}

void value_append_string(char* string) {
    int length = strlen(string);
    for (int i = 0; i < length; i++) {
        value_append(string[i]);
    }
}

function<bool (char)> identifier_comparator = [](char c) {
    bool is_matching = is_in_range(c, TOKENRANGE_LOWERCASE_MIN, TOKENRANGE_LOWERCASE_MAX)
        || is_in_range(c, TOKENRANGE_UPPERCASE_MIN, TOKENRANGE_UPPERCASE_MAX)
        || is_in_range(c, TOKENRANGE_NUMBER_MIN, TOKENRANGE_NUMBER_MAX)
        || c == CHAR_UNDERSCORE
        || c == CHAR_ASTERISK
        || c == CHAR_ACCENT;
    bool is_legal = last_char_of(value) != CHAR_ASTERISK 
        || last_char_of(value) == CHAR_ASTERISK && c == CHAR_ASTERISK;
    return is_matching && is_legal;
};

function<bool (char)> number_comparator = [](char c) {
    return is_in_range(c, TOKENRANGE_NUMBER_MIN, TOKENRANGE_NUMBER_MAX)
           || c == CHAR_UNDERSCORE
           || c == CHAR_DOT
           || c == CHAR_E 
           || c == CHAR_DASH;
};

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
        next_char_count(0);
        return true;
    }
    return false;
}

char* consume_next(function <int (char)> compare) {
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

// goes through an array with strings of 3 characters
char* consume_one_of(char *array) {
    // @Todo: check for eof
    
    int index = 0;
    while (array[index] != 0 && stringCount > i) { // if reached the end (array[i][0] == 0)
        bool is_matching = true;
        int length = 0;
        for (int w = 0; w < 3; w++) {
            char array_value = array[index + w];
            char code_value = code[i + w];

            if (array_value != 0 && array_value != code_value) {
                is_matching = false;
                break;
            }
            if (array_value != 0 && array_value == code_value) {
                length += 1;
            }
        }

        if (is_matching) {
            auto result = new char[length];
            result[0] = code[i + 0];
            if (length > 1) {
                result[1] = code[i + 1];
            }
            if (length > 2) {
                result[2] = code[i + 2];
            }

            // 1 symbol is consumed at the end of the loop
            next_char_count(length - 1);
            return result;
        }

        index += 3;
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

Token* make_token_separator() {
    Token *token = make_token(SEPARATOR);
    token->stringValue = get_value();
    return token;
}

bool is_next_three_quotes_after(int n) {
    if (!(stringCount > i + 2 + n)) {
        return false;
    }
    return code[i+n] == CHAR_QUOTE && code[i+1+n] == CHAR_QUOTE && code[i+2+n] == CHAR_QUOTE;
}

void fail_with_error(const char* message, Cursor *start, Cursor *end, int line_number) {
    std::cout << "error occured: " << message << "\n(context: L" << line_number << ")" << endl;
    exit(1);
}

Output* lexer_analyze(char* string) {

    // initialization
    cursor = new Cursor();
    tokens = new Token[1024];

    cursor->line_number = 1;

    code = string;
    stringCount = strlen(string);
    character = string[0];

    while (stringCount > i) {
        bool should_fallthrough = false;

        if (character == CHAR_QUOTE) {
            // STRING LITERAL
            Cursor *start = copy_cursor(cursor);

            auto is_multiline = is_next_three_quotes_after(0);
            if (is_multiline) {
                next_char_count(3);
                if (!consume(CHAR_NEWLINE)) {
                    fail_with_error("newlineExpectedBeforeMultilineStringLiteral", cursor, cursor, __LINE__);
                }
            } else {
                if (!next_char()) {
                    fail_with_error("unexpectedEndOfFile", cursor, cursor, __LINE__);
                }
            }

            value_reset();
            while (stringCount > i) {
                // if char == C.newline { /* @Todo: wtf is this? */ }

                if (character == CHAR_BACKSLASH) {
                    auto next = peek_next();
                    if (next == NULL) {
                        fail_with_error("unexpectedEndOfFile", cursor, cursor, __LINE__);
                    }

                    switch (*next) {
                    case CHAR_ZERO: { value_append(0); break; }
                    case CHAR_N: { value_append(CHAR_NEWLINE); break; }
                    case CHAR_R: { value_append(CHAR_RETURN); break; }
                    case CHAR_T: { value_append(CHAR_TAB); break; }
                    case CHAR_BACKSLASH: { value_append(CHAR_BACKSLASH); break; }
                    case CHAR_QUOTE: { value_append(CHAR_QUOTE); break; }
                    default: { fail_with_error("unexpectedCharacterToEscape", cursor, cursor, __LINE__); }
                    }

                    if (!next_char() || !next_char()) {
                        fail_with_error("unexpectedEndOfFile", cursor, cursor, __LINE__);
                    }
                    continue;
                }

                if (is_multiline) {
                    if (peek_next() == NULL) {
                        fail_with_error("unexpectedEndOfFile", cursor, cursor, __LINE__);
                    } else if (is_next_three_quotes_after(0)) {
                        fail_with_error("newlineExpectedAfterMultilineStringLiteral", cursor, cursor, __LINE__);
                    } else if (character == CHAR_NEWLINE && is_next_three_quotes_after(1)) {
                        next_char_count(4);

                        auto next = peek_next();
                        if (*next != CHAR_NEWLINE && *next != CHAR_SEMICOLON) {
                            fail_with_error("newlineExpectedAfterMultilineStringLiteral", cursor, cursor, __LINE__);
                        } else {
                            auto token = make_token(STRINGLITERAL);
                            token->stringValue = get_value();
                            token_append(token, start, cursor);
                            break;
                        }
                    }
                } else {
                    if (consume(CHAR_QUOTE)) { // @Note: if consume(string: [C.quote]) {
                        auto token = make_token(STRINGLITERAL);
                        token->stringValue = get_value();
                        token_append(token, start, cursor);
                        break;
                    } else if (*peek_next() == CHAR_NEWLINE) {
                        fail_with_error("newLineInStringLiteral", cursor, cursor, __LINE__);
                    }
                }

                value_append(character);
                if (!next_char()) {
                    fail_with_error("unexpectedEndOfFile", cursor, cursor, __LINE__);
                }
            }
        } else if (character == CHAR_SEMICOLON || character == CHAR_COMMA) {
            // SEPARATORS
            value_reset();
            value_append(character);
            auto separator_token = make_token_separator();
            token_append(separator_token, cursor, cursor);
        } else if (character == CHAR_NEWLINE || character == CHAR_SPACE) {
            // skip
        } else if (
               is_in_range(character, TOKENRANGE_LOWERCASE_MIN, TOKENRANGE_LOWERCASE_MAX)
            || is_in_range(character, TOKENRANGE_UPPERCASE_MIN, TOKENRANGE_UPPERCASE_MAX)
            || character == CHAR_UNDERSCORE
            || character == CHAR_POUND 
            || character == CHAR_ACCENT
        ) {
            // KEYWORDS / IDENTIFIERS / DIRECTIVES / BOOL LITERALS
            Cursor *start = copy_cursor(cursor);

            bool is_directive = consume(CHAR_POUND);
            if (is_directive) {
                if (!next_char() || character == 0 || character == CHAR_SPACE) {
                    fail_with_error("emptyDirectiveName", start, cursor, __LINE__);
                } else if (
                       !is_in_range(character, TOKENRANGE_LOWERCASE_MIN, TOKENRANGE_LOWERCASE_MAX)
                    && !is_in_range(character, TOKENRANGE_UPPERCASE_MIN, TOKENRANGE_UPPERCASE_MAX)
                    && character != CHAR_UNDERSCORE
                    )  {
                        fail_with_error("unexpectedDirectiveName", start, cursor, __LINE__);
                    }
            }

            value_reset();
            value_append(character);

            while (true) {
                char* next = consume_next(identifier_comparator);
                if (next == NULL) {
                    break;
                }
                value_append(*next);
            }

            bool is_not_keyword = value[0] == CHAR_ACCENT 
                && last_char_of(value) == CHAR_ACCENT
                && value_length >= 3;
            if (is_not_keyword) {
                char *copy = get_value_in_range(1, value_length-1);
                value_reset();
                value_append_string(copy);
            }

            int idx = index_in_value_of(CHAR_ACCENT);
            if (idx != -1) {
                // @Todo: add idx to cursor to 'start' to calculate the position of the unexpected symbol
                fail_with_error("unexpectedCharacter", start, start, __LINE__);
            }

            if (string_compare(value, "void")) {
                Token *token = make_token(VOIDLITERAL);
                token_append(token, start, cursor); // @Todo: looks wrong
            } else if (string_compare(value, "null\0")) {
                Token *token = make_token(NULLLITERAL);
                token_append(token, start, cursor);
            } else if (string_compare(value, "true\0")) {
                Token *token = make_token(BOOLLITERAL);
                token->boolValue = true;
                token_append(token, start, cursor);
            } else if (string_compare(value, "false\0")) {
                Token *token = make_token(BOOLLITERAL);
                token->boolValue = false;
                token_append(token, start, cursor);
            } else if (is_directive) {
                if (value == 0) {
                    fail_with_error("emptyDirectiveName", start, cursor, __LINE__);
                }
                Token *token = make_token(DIRECTIVE);
                token->stringValue = get_value();
                token_append(token, start, cursor);
            } else if (*value == CHAR_UNDERSCORE) {
                fail_with_error("invalidIdentifierUnderscore", start, cursor, __LINE__);
            } else {
                Token *token = make_token(IDENTIFIER);
                token->stringValue = get_value();
                token_append(token, start, cursor);
            }

        } else if (
            is_in_range(character, TOKENRANGE_NUMBER_MIN, TOKENRANGE_NUMBER_MAX)
            || character == CHAR_DOT
            || character == CHAR_DASH
        ) {
            // NUMBER LITERALS
            Cursor *start = copy_cursor(cursor);

            if (!is_in_range(character, TOKENRANGE_NUMBER_MIN, TOKENRANGE_NUMBER_MAX)) {
                char* next = peek_next();
                if (next == NULL || !is_in_range(*next, TOKENRANGE_NUMBER_MIN, TOKENRANGE_NUMBER_MAX)) {
                    should_fallthrough = true;
                }
            }

            if (!should_fallthrough) {
                value_reset();
                value_append(character);

                while (true) {
                    char* next = consume_next(number_comparator);
                    if (next == NULL) {
                        break;
                    }
                    if (value_length >= 1 && *next == CHAR_DASH && last_char_of(value) != CHAR_E) {
                        fail_with_error("unexpectedMinusInNumberLiteral", start, cursor, __LINE__);
                    }
                    if (*next == CHAR_DOT && string_contains(value, CHAR_DOT)
                        || *next == CHAR_E && string_contains(value, CHAR_E)) {
                        if (*next == CHAR_DOT) {
                            fail_with_error("unexpectedDotInFloatLiteral", start, cursor, __LINE__);
                        } else {
                            fail_with_error("unexpectedEInFloatLiteral", start, cursor, __LINE__);
                        }
                    }
                    if (*next == CHAR_UNDERSCORE) {
                        continue;
                    }
                    value_append(*next);
                }

                char *next = peek_next();
                if (next != NULL) {
                    // @Todo: this probably doesn't work out because 
                    // punctuators and operators are multidimentional arrays
                    if (!( string_contains((char*) separators, *next)
                        || string_contains((char*) punctuators, *next)
                        || string_contains((char*) operators, *next))
                    ) {
                        fail_with_error("unexpectedCharacterInNumber", cursor, cursor, __LINE__);
                    }
                }

                if (string_compare(value, (char*) &CHAR_DASH) || only_contains_character(value, CHAR_DOT)) {

                } else if (string_contains(value, CHAR_E) || string_contains(value, CHAR_DOT)) {
                    Token *token = make_token(FLOATLITERAL);
                    token->doubleValue = atof(value);
                    token_append(token, start, cursor);
                } else {
                    Token *token = make_token(INTLITERAL);
                    token->intValue = atoi(value);
                    token_append(token, start, cursor);
                }
            }   
        }

        if (should_fallthrough) {
            // PUNCTUATORS, OPERATORS
            Cursor *start = copy_cursor(cursor);

            auto punctuator_value = consume_one_of((char*) punctuators[0]);
            if (punctuator_value != NULL) {
                Token *token = make_token(PUNCTUATOR);
                token->stringValue = punctuator_value;
                token_append(token, start, cursor);
            } else {
                auto operator_value = consume_one_of((char*) operators[0]);
                if (operator_value != NULL) {
                    Token *token = make_token(OPERATOR);
                    token->stringValue = operator_value;
                    token_append(token, start, cursor);
                } else {
                    if (character == CHAR_SPACE || CHAR_NEWLINE) {
                        // no-op
                    } else if (character != 0) {
                        auto previous = copy_cursor(start);
                        withdraw_character(previous);
                        fail_with_error("unexpectedCharacter", previous, cursor, __LINE__);
                    }
                }
            }
        }

        if (character == 0 || !next_char()) {
            token_append(make_token(ENDOFFILE), cursor, cursor);
            break;
        }
    }

    Output *output = new Output();
    output->tokens = tokens;
    output->tokens_count = tokens_count;
    output->lines_processed = cursor->line_number;
    return output;
}
