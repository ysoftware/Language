//
//  IRGen.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class IR {
    
    // @Todo: this worked, but it sounds like a really bad idea
    // I need to investigate how this is supposed to be actually done
    
    internal var stringLiterals: [String: StringLiteral] = [:]
    internal var procedures: [String: ProcedureDeclaration] = [:]
    
    internal var globalCounter = 0
    internal var globalScope = ""
    
    /// Use this to generate LLVM IR code
    func generateIR(globalScope ast: Scope) -> String {
        let code = processStatements(ast.code, ident: 0)
        return globalScope + "\n" + code
    }
    
    internal func count() -> Int {
        globalCounter += 1
        return globalCounter - 1
    }
    
    private func emitGlobal(_ string: String) {
        globalScope += string + "\n"
    }
    
    private func processStatements(_ statements: [Statement], ident: Int) -> String {
        var scope = ""
        
        func emitLocal(_ string: String? = "") {
            guard let string = string else { return }
            let identation = String(repeating: "\t", count: ident)
            scope += "\(identation)\(string)\n"
        }
        
        // All statements go here
        
        for expression in statements {

            switch expression {
                
            case let loop as WhileLoop:
                let counter = count()
                let bodyLabel = "loop.\(counter).body"
                let continueLabel = "loop.\(counter).continue"
                
                let (expCode, expVal) = getExpressionResult(loop.condition, ident: ident)
                emitLocal("br label %\(counter) ; terminating previous block")
                emitLocal()
                emitLocal("; %\(counter) loop condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(bodyLabel), label %\(continueLabel)")
                
                let loopBody = processStatements(loop.block.code, ident: ident + 1)
                emitLocal()
                emitLocal("\(bodyLabel):")
                emitLocal(loopBody)
                emitLocal("br label %\(counter)")
                
                // continue
                emitLocal()
                emitLocal("\(continueLabel):")
                
            case let condition as Condition:
                let hasElse = !condition.elseBlock.isEmpty
                let (expCode, expVal) = getExpressionResult(condition.condition, ident: ident)
                
                let counter = count()
                let bodyLabel = "; if.\(counter) body"
                let continueLabel = "if.\(counter).continue"
                let elseLabel = hasElse ? "if.\(counter).else" : continueLabel
                
                emitLocal()
                emitLocal("; if condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(counter), label %\(elseLabel)")
                
                let ifBody = processStatements(condition.block.code, ident: ident + 1)
                emitLocal()
                emitLocal("\(bodyLabel):")
                emitLocal(ifBody)
                emitLocal("br label %\(continueLabel)")
                
                if hasElse {
                    let elseBody = processStatements(condition.elseBlock.code, ident: ident + 1)
                    emitLocal()
                    emitLocal("\(elseLabel):")
                    emitLocal(elseBody)
                    emitLocal("br label %\(continueLabel)")
                }
                
                emitLocal()
                emitLocal("\(continueLabel):")
                
            case let procedure as ProcedureDeclaration:
                procedures[procedure.id] = procedure
                let arguments = getProcedureArgumentString(from: procedure)
                let returnType = matchType(procedure.returnType.name)
                
                if procedure.flags.contains(.isForeign) {
                    emitGlobal("declare \(returnType) @\(procedure.name) (\(arguments))")
                }
                else {
                    emitLocal("define \(returnType) @\(procedure.name) (\(arguments)) {")
                    _ = count() // implicit entry block takes the next name
                    let body = processStatements(procedure.scope.code, ident: ident + 1)
                    emitLocal(body)
                    emitLocal("}")
                }
                
            case let call as ProcedureCall:
                let (expCode, _) = getExpressionResult(call, ident: ident)
                emitLocal(expCode)
                
            case let literal as StringLiteral:
                guard let value = getCString(from: literal.value) else {
                    // @Todo: make sure we have to assert here
                    report("Unsupported character in string literal. Only supporting ascii for now.")
                }
                stringLiterals[literal.id] = literal
                emitGlobal("@\(literal.id) = constant [\(literal.value.count) x i8] c\"\(value)\"")
                
            case let variable as VariableDeclaration:
                let (expCode, expVal) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(expCode)
                // @Todo: support constant variables
                // do it at ast building?
                let type = matchType(variable.type.name)
                emitLocal("%\(variable.id) = alloca \(type)")
                emitLocal("store \(type) \(expVal), \(type)* %\(variable.id)")
                
            case let variable as VariableAssignment:
                let (expCode, expVal) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(expCode)
                let type = matchType(variable.expression.type.name)
                emitLocal("store \(type) \(expVal), \(type)* %\(variable.receiverId)")
                
            case let ret as Return:
                let (expCode, expVal) = getExpressionResult(ret.value, ident: ident)
                emitLocal(expCode)
                emitLocal("ret \(matchType(ret.value.type.name)) \(expVal)")
                
            default:
                report("Undefined expression:\n\(expression)")
            }
        }
        
        return scope.trimmingCharacters(in: .newlines)
    }
}
