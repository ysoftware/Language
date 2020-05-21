#!/bin/bash
clear; printf '\033[3J';
printf "Running tests...\n\n"

for i in {0..3}
do

printf 'Test %s: ' "$i"
/Users/yerokhin/Library/Developer/Xcode/DerivedData/Compiler-gxtfqytswywkrqgfssbpireaoowy/Build/Products/Debug/Compiler -ast$i \
    > generated.ll && lli generated.ll > /dev/null && rm -rf generated.ll \
    && ( printf '%s' ${string:5:-2} | printf ' ✅\n') \
    \
    || printf 'Failed ❌\n\n'
done
