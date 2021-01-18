#include "Lexer.cpp"

enum RunArgumentsFlags {
    HasFile = 1
};

struct RunArguments {
    RunArgumentsFlags flags;
    char *file_path;
};

inline RunArgumentsFlags operator | (RunArgumentsFlags a, RunArgumentsFlags b) {
    return static_cast<RunArgumentsFlags>(static_cast<int>(a) | static_cast<int>(b));
}

RunArguments* parse_arguments(int argc, char *argv[]) {
    auto *arguments = new RunArguments();

    bool isLookingForFile = false;
    for (int i = 1; i < argc; ++i) {
        char *argument = argv[i];

        if (strcmp(argument, "-file")) {
            cout << "found -file" << endl;
            isLookingForFile = true;
        }
        
        if (isLookingForFile) {
            cout << "found file name" << endl;
            arguments->file_path = argument;
            arguments->flags = arguments->flags | HasFile;
            isLookingForFile = false;
        }
    }

    if (isLookingForFile) {
        return NULL;
    } else {
        return arguments;
    }
}
