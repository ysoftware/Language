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
            
            // PROCEDURE DECLARATION
            if let procedure = expression as? ProcedureDeclaration {
                
                let arguments = getProcedureArgumentString(from: procedure)
                let returnType = matchType(procedure.returnType.name)
                
                if procedure.flags.contains(.isForeign) {
                    
                    // @Todo: assert if not in global scope?
                    // do it at ast building
                    
                    guard procedure.scope.isEmpty else {
                        report("Foreign procedures must not have a body")
                    }
                    emitGlobal("declare \(returnType) @\(procedure.name) (\(arguments))")
                }
                else {
                    emitLocal("define \(returnType) @\(procedure.name) (\(arguments)) {")
                    _ = count() // implicit entry block takes the next name
                    let body = processStatements(procedure.scope.code, ident: ident + 1)
                    emitLocal(body)
                    emitLocal("}")
                }
                procedures[procedure.id] = procedure
            }
                
                // PROCEDURE CALL
            else if let call = expression as? ProcedureCall {
                
                // just calling the procedure, ignoring result value
                let (eCode, _) = getExpressionResult(call, ident: ident)
                emitLocal(eCode)
            }
                
                // CONDITION
            else if let condition = expression as? Condition {
                guard ident > 0 else {
                    report("Conditional statements are not allowed at global scope")
                }
                
                let hasElse = !condition.elseBlock.isEmpty
                
                emitLocal("; condition evaluation")
                let (eCode, eValue) = getExpressionResult(condition.condition, ident: ident)
                emitLocal(eCode)
                
                let ifCount = count()
                let continueLabel = "continue_\(ifCount)"
                let elseLabel = hasElse ? "else_\(ifCount)" : continueLabel
                
                emitLocal("br i1 \(eValue), label %\(ifCount), label %\(elseLabel)")
                
                let ifBody = processStatements(condition.block.code, ident: ident + 1)
                
                emitLocal()
                emitLocal("; %\(ifCount) if block")
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
            }
                
                // STRING LITERAL
            else if let literal = expression as? StringLiteral {
                // @Todo: make sure we have to assert here
                guard let value = getCString(from: literal.value) else {
                    report("Unsupported character in string literal. Only supporting ascii for now.")
                }
                emitGlobal("@\(literal.id) = constant [\(literal.value.count) x i8] c\"\(value)\"")
                stringLiterals[literal.id] = literal
            }
                
                // VARIABLE DECLARATION
            else if let variable = expression as? VariableDeclaration {
                // @Todo: support constant variables
                // do it at ast building?
                
                let (eCode, eValue) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(eCode)
                
                let type = matchType(variable.type.name)
                emitLocal("%\(variable.id) = alloca \(type)")
                emitLocal("store \(type) \(eValue), \(type)* %\(variable.id)")
            }
                
                // ASSIGNMENT
            else if let variable = expression as? VariableAssignment {
                
                let (eCode, eValue) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(eCode)
                
                let type = matchType(variable.expression.type.name)
                emitLocal("store \(type) \(eValue), \(type)* %\(variable.receiverId)")
            }
                
                // RETURN
            else if let ret = expression as? Return {
                
                let (eCode, eValue) = getExpressionResult(ret.value, ident: ident)
                
                emitLocal(eCode)
                emitLocal("ret \(matchType(ret.value.type.name)) \(eValue)")
            }
                
            else {
                
                report("Undefined expression:\n\(expression)")
            }
        }
        
        return scope.trimmingCharacters(in: .newlines)
    }
}
