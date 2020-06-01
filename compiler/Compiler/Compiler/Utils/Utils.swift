//
//  Utils.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func plural(_ value: Int) -> String { value == 1 ? "" : "s" }

extension String {
    
    func endIndex(offsetBy offset: Int) -> String.Index { index(endIndex, offsetBy: offset) }
    func startIndex(offsetBy offset: Int) -> String.Index { index(startIndex, offsetBy: offset) }
    subscript(index: Int) -> Character { self[startIndex(offsetBy: index)] }
}

extension Result where Failure == ParserError {
    
    func then(_ block: (Success)->Void) -> ParserError? {
        switch self {
        case .success(let value): block(value); return nil
        case .failure(let error): return error
        }
    }
}

extension Ast {
    
    func equals(to ast: Ast?) -> Bool {
        guard let ast = ast else { return false }
        switch (self, ast) {
        case (let l as Code, let r as Code): return l == r
        case (let l as Value, let r as Value): return l == r
        case (let l as ProcedureDeclaration, let r as ProcedureDeclaration): return l == r
        case (let l as StructDeclaration, let r as StructDeclaration): return l == r
        case (let l as VariableDeclaration, let r as VariableDeclaration): return l == r
        case (let l as VariableAssignment, let r as VariableAssignment): return l == r
        case (let l as Condition, let r as Condition): return l == r
        case (let l as WhileLoop, let r as WhileLoop): return l == r
        case (let l as Break, let r as Break): return l == r
        case (let l as Continue, let r as Continue): return l == r
        case (let l as Return, let r as Return): return l == r
        case (let l as BinaryOperator, let r as BinaryOperator): return l == r
        case (let l as ProcedureCall, let r as ProcedureCall): return l == r
        case (let l as StringLiteral, let r as StringLiteral): return l == r
        case (let l as IntLiteral, let r as IntLiteral): return l == r
        case (let l as FloatLiteral, let r as FloatLiteral): return l == r
        case (let l as BoolLiteral, let r as BoolLiteral): return l == r
        case (is VoidLiteral, is VoidLiteral): return true
        default: return false
        }
    }
}
