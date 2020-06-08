#!/bin/bash

/Users/yerokhin/Library/Developer/Xcode/DerivedData/Compiler-gxtfqytswywkrqgfssbpireaoowy/Build/Products/Debug/Compiler -file $1 > generated.ll;
cat generated.ll;
printf "Program output:\n"; 
lli generated.ll; rm -rf generated.ll; 
printf "\n";

