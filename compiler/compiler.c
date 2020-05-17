/*

compilation steps:

    1. parse code to create AST
    2. type check and setup AST
    3. generate LLVM IR
    4. use LLVM to assemble and link


development steps:

    ✔️. use LLVM to parse manually-written IR 
    2. generate IR from some manually written and type-set-up AST
    3. parse code into AST
    4. type check AST and connect it to IR generation

*/