# Language
---
*This project has been put on hold. The work ended at implementing different kinds of arrays.*

---
## Excercise in developing a programming language


I'm using Swift because I feel comfortable with it.
This is my very first experience in compiler development, therefore, I'm not taking any criticism and not reading any tutorials.

I want to stumble into as many mistakes and problems as I can, and solve them on my own.

## Progress:
- [x] use LLVM to parse manually-written IR (part 1)
- [x] generate IR from some manually written and pre-typed AST
- [x] develop lexer (tokenizer)
- [x] **parse code into AST**
- [x] hook up to IR generation
- [ ] second pass type inference
- [x] testing AST and IR generation
- [ ] IR generation for more complicated things (part 2)
- [ ] static analyzer (all paths return a value, unused values)


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
func entry_point() -> Int32 #main { ... }
```
 
 Array Literals
 ```
 a : Int[3] = [0, 1, 2];
 b : Float[3] = [0, 1, 2]
 c := [0, 1, 2]              // Int[3] 
 d := [0.1, 1, 2]            // Float[3]
 ```

 
 
## Ideas Roadmap:

#### If/switch expression
```
enum Values { A, B, C };
value := Values.A;

name := switch (value) {
  case A: #provide "A";
  case B: #provide "B";
  case C: #provide "C";
}

description := if (name == Values.B) {
  #provide "The name is B."
}
else {
  #provide "The name is not B."
}

// name == "A"
// description == "The name is not B."
```

#### Not-really-objective
Use dot syntax for calling procedures where first argument is (pointer to) an instance of this class.
Sort of like namespacing, but it will require procedure overloading to resolve collisions.
```
func append(list: List*, value: Int) -> Node*;
list.append(1);       
/* instead of: */ list_append(list, 1);
```

#### Polymorphic procedures
 ```
func array_add(_ array: *($T[]), _ element: T);
```

#### Dynamic arrays (probably written in the language as a part of the st. lib)
```
a := [1, 2, 3, 4, ...] // use varargs as syntax for dynamic array
```

Also:
- Procedures overloading
