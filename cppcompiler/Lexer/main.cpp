#include "Lexer.cpp"

int main() {

    char* data = (char*) "\"aawdwad\"\0";
    auto *output = lexer_analyze(data);

    cout << "compiler tokens: " << output->tokens_count << endl;

    print_token(output->tokens[0]);
}