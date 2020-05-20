// clang test.c && ./a.out && rm -rf a.out
#include <stdio.h>

int main() {

    int64_t a = 50000000000;
    while (a != 0) {
        a = a - 1;
    }

    return 0;
}