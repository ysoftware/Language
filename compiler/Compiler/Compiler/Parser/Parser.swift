//
//  Parser.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

class Parser {
    
}

// func printf(format: String, arguments: Int32, ...) #foreign
//
// func main() -> Int32 {
//     a: Int = 0
//     outerLoop: while true {
//         while true {
//             a = a + 1
//             if a > 500 { break outerLoop }
//             if a == 100 { break }
//             if a > 1 { continue }
//             else { printf("Did not continue! a is %d\n\", a) }
//         }
//         printf("Broke out of loop 1, a is %d\n\", a)
//     }
//     printf("Broke out of loop 2, a is %d\n\", a)
// }
 
/*
 
 unsolvedTokens: [String] // come back to uncertain tokens
 scopes: [Scope] //
 
 */



/*
 
 func       -> keyword      [fhead]
 printf     -> identifier   [fhead] function name
 (          -> punctuator   [fhead, fargs] start of arguments declaration
 format     -> identifier   [fhead, fargs, farg] argument name
 :          -> punctuator   [fhead, fargs, farg] type identifier next
 String     -> identifier   [fhead, fargs] type
 ,          -> punctuator   [fhead, fargs] more arguments, name or varargs next
 arguments  -> identifier   [fhead, fargs, farg] argument name
 :          -> punctuator   [fhead, fargs, farg] type identifier next
 Int32      -> identifier   [fhead, fargs] type
 ,          -> punctuator   [fhead, fargs] more arguments, name or varargs next
 ...        -> punctuator   [fhead, fargs] variadic flag
 )          -> punctuator   [fhead] end of arguments
 #          -> punctuator   [fhead] directive name next
 foreign    -> identifier   [fhead] directive name
 \n         -> punctuator   [fhead] not a token in function declaration
 
 
 func       -> keyword      [fhead] closing previous func declaration, starting a new one
 main       -> identifier   [fhead] function name
 (          -> punctuator   [fhead, fargs] start of arguments declaration
 )          -> punctuator   [fhead, fargs] end of arguments declaration
 ->         -> punctuator   [fhead] type identifier next
 Int32      -> identifier   [fhead] return type
{           -> punctuator   [fbody] end of func head, starting with body
 
 
 a          -> identifier x [fbody] variable name or label
 :          -> punctuator x [fbody] label / type
 Int        -> identifier   [fbody, vardef] we don't expect identifiers after label name,
                                                so this is a variable declaration and this is a type. solving...
 =          -> operator     [fbody, vardef] assign operator
 0          -> literal      [fbody, vardef, expr] closing the var assignment
 
 \n         -> punctuator x [fbody, vardef, expr] this will become a separator
 outerLoop  -> identifier x [fbody] variable name or label or function name! ending expression, solving...
 :          -> punctuator x [fbody] label / type
 while      -> keyword      [fbody, whilecond] while can have labels. unsolved tokens...
 true       -> literal      [fbody, whilecond] condition over, next body
 {          -> punctuator   [fbody, whilebody] start while body
 
 a          -> identifier x [fbody, whilebody] variable name or label
 =          -> punctuator   [fbody, whilebody, assign] assigning some variable, solving...
 a          -> identifier x [fbody, whilebody, assign, expr] name of variable (or function)
 +          -> punctuator   [fbody, whilebody, assign, expr] operator, solving...
 1          -> literal      [fbody, whilebody, assign, expr]
 \n         -> punctuator   [fbody, whilebody, assign, expr]
 if         -> keyword      [fbody, whilebody] ending assignment expression
 */

