#include "main.h"

int main(int argc, char **argv) {
    auto *arguments = parse_arguments(argc, argv);

    if (arguments == NULL || arguments->file_path == NULL) {
        cout << "Could not parse arguments" << endl;
        exit(1);
    }

    // read program file
    char* file_buffer = load_file_into_buffer(arguments->file_path);
    if (file_buffer == NULL) {
        cout << "Could not load file: " << arguments->file_path << endl;
        exit(1);
    }

    cout << "\n----\n";

    // run lexer
    auto *output = lexer_analyze(file_buffer);
    cout << "lexer output tokens: " << output->tokens_count << endl;

    for (int i = 0; i < output->tokens_count; i++) {
        print_token(output->tokens[i]);
    }

    // clean up
    free(file_buffer);
}
