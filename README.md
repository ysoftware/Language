# Language

## Упражнение на разработку языка программирования


## Прогресс:
- [x] use LLVM to parse manually-written IR
- [x] generate IR from some manually written and pre-typed AST
- [x] develop lexer (tokenizer)
- [ ] parse code into AST
- [ ] type infer AST and hook it to IR generation


## Syntax Description

*Declaration*
```
a : Int = 0;        // variable 
b : Float : 0.1;    // constant

a := 1; // variable
b :: 2; // constant
```
 
 *Pointer type*
 ```
 a := 3;
 b := *a; // *Int
 ```
 
 *Procedure declaration*
```
func printf(_ format: String, _ arguments: Int32, ...) #foreign;
```
 
 Array Literals
 ```
 a : Int[3] = [0, 1, 2];
 b : Float[3] = [0, 1, 2]
 c := [0, 1, 2]              // Int[3] 
 d := [0.1, 1, 2]            // Float[3]
 f := (Float[15])[1, 2, 3]
 ```

 
 
## Future Feature Roadmap:

Polymorphic procedures
 ```
func array_add(_ array: *($T[]), _ element: T);
```

Variable length arrays
```
// first I need to learn how they work
a := [1, 2, 3, 4, ...] // use varargs for not constraining to length?
```

