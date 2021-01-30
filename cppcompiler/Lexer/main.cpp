#include <chrono> 
#include "main.h"

using namespace std::chrono; 

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

    auto start = high_resolution_clock::now();
    
    // run lexer
    auto *output = lexer_analyze(file_buffer);
    cout << "Token count: " << output->tokens_count << endl;

    for (int i = 0; i < output->tokens_count; i++) {
        print_token(output->tokens[i]);
    }
    
    auto stop = high_resolution_clock::now();
    auto micros = (double) duration_cast<microseconds>(stop - start).count();
    auto seconds = micros / 1000000;
    cout.precision(2);
    cout << "Everything took " << seconds << " sec." << endl;

    // clean up
    free(file_buffer);
}
