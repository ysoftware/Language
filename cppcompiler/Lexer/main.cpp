#include "main.h"

int main(int argc, char **argv) {
    auto *arguments = parse_arguments(argc, argv);

    if (arguments != NULL) {
        bool hasFile = arguments->flags | HasFile;
        cout << "HasFile: " << (int) (hasFile) << endl;
        if (hasFile && arguments->file_path != NULL) {
            cout << arguments->file_path << endl;
        }
    }

    cout << "\n----\n";

    char* data = (char*) "\"aawdwad\"\0";
    auto *output = lexer_analyze(data);
    cout << "compiler tokens: " << output->tokens_count << endl;
    print_token(output->tokens[0]);
}
