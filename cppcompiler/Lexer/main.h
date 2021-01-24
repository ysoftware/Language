// #include "Lexer.cpp"

#include "Lexer.cpp"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <iostream>

using namespace std;

// ARGUMENT PARSING

enum RunArgumentsFlags {
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

        if (isLookingForFile) {
            arguments->file_path = argument;
            isLookingForFile = false;
        } else if (strcmp(argument, "-file") == 0) {
            isLookingForFile = true;
        }
    }

    if (isLookingForFile) {
        return NULL;
    } else {
        return arguments;
    }
}

// FILE LOADING

char* load_file_into_buffer(char const* path) {
    char* buffer = 0;
    long length;
    FILE * f = fopen (path, "rb"); //was "rb"

    if (f)
    {
      fseek (f, 0, SEEK_END);
      length = ftell (f);
      fseek (f, 0, SEEK_SET);
      buffer = (char*)malloc ((length+1)*sizeof(char));
      if (buffer)
      {
        fread (buffer, sizeof(char), length, f);
      }
      fclose (f);
    }
    buffer[length] = '\0';
    return buffer;
}