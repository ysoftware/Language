//
//  IRGen.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class IR {
    
    // @Todo: arrays
    // @Todo: structs
    
    // @Todo: this worked, but it sounds like a really bad idea
    // I need to investigate how this is supposed to be actually done
    internal var stringLiterals: [String: StringLiteral] = [:]
    internal var procedures: [String: ProcedureDeclaration] = [:]
    
    internal var globalCounter = 0
    internal var globalScope = ""
    
    /// Use this to generate LLVM IR code
    func generateIR(globalScope ast: Scope) -> String {
        let code = processStatements(ast.code, ident: 0, contexts: [])
        return globalScope + "\n" + code
    }
    
    /// Returns the current counter value, also advances it for the next time
    internal func count() -> Int {
        defer { globalCounter += 1 }
        return globalCounter
    }
    
    /// Write a line of IR text into the global scope
    private func emitGlobal(_ string: String) {
        globalScope += string + "\n"
    }
    
    /// Process statements and return IR text
    private func processStatements(_ statements: [Statement],
                                   ident: Int,
                                   contexts: [StatementContext]) -> String {
        
        var scope = ""
        let identation = String(repeating: "\t", count: ident)
        
        /// Write a line of IR text into the local scope
        func emitLocal(_ string: String? = "") {
            guard let string = string else { return }
            scope += "\(identation)\(string)\n"
        }
        
        // All statements go here
        for expression in statements {
            switch expression {
            
            case let loop as WhileLoop:
                let counter = count()
                let bodyLabel = "loop.\(counter).body"
                let continueLabel = "loop.\(counter).continue"
                let context = LoopContext(userLabel: loop.userLabel,
                                          breakLabel: continueLabel,
                                          continueLabel: "%\(counter)")
                
                let (expCode, expVal) = getExpressionResult(loop.condition, ident: ident)
                emitLocal()
                emitLocal("br label %\(counter) ; terminating previous block")
                emitLocal()
                emitLocal("; %\(counter) loop.\(counter).condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(bodyLabel), label %\(continueLabel)")
                
                let loopBody = processStatements(loop.block.code,
                                                 ident: ident + 1,
                                                 contexts: contexts + [context])
                emitLocal()
                emitLocal("\(bodyLabel): ; user label \(loop.userLabel ?? "[not set]")")
                emitLocal(loopBody)
                emitLocal("br label %\(counter)")
                
                // continue
                emitLocal()
                emitLocal("\(continueLabel): ; exiting loop.\(counter), user label \(loop.userLabel ?? "[not set]")")
                
            case let br as Break:
                _ = count() // eat block # after br
                let label = getLoopContext(from: contexts, with: br.userLabel).breakLabel
                emitLocal()
                emitLocal("br label %\(normalizeLabel(label)) ; loop break, user label \(br.userLabel ?? "[not set]")")
                
            case let cont as Continue:
                _ = count() // eat block # after br
                let label = getLoopContext(from: contexts, with: cont.userLabel).continueLabel
                emitLocal()
                emitLocal("br label %\(normalizeLabel(label)) ; loop continue, user label \(cont.userLabel ?? "[not set]")")
                
                
            case let condition as Condition:
                let hasElse = !condition.elseBlock.isEmpty
                let (expCode, expVal) = getExpressionResult(condition.condition, ident: ident)
                
                let counter = count()
                let bodyLabel = "; %\(counter) if.\(counter).body"
                let continueLabel = "if.\(counter).continue"
                let elseLabel = hasElse ? "if.\(counter).else" : continueLabel
                
                emitLocal()
                emitLocal("; if condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(counter), label %\(elseLabel)")
                
                let ifBody = processStatements(condition.block.code,
                                               ident: ident + 1,
                                               contexts: contexts)
                emitLocal()
                emitLocal("\(bodyLabel):")
                emitLocal(ifBody)
                emitLocal("br label %\(continueLabel)")
                
                if hasElse {
                    let elseBody = processStatements(condition.elseBlock.code,
                                                     ident: ident + 1,
                                                     contexts: contexts)
                    emitLocal()
                    emitLocal("\(elseLabel):")
                    emitLocal(elseBody)
                    emitLocal("br label %\(continueLabel) ; exiting else.\(counter)")
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
                    let body = processStatements(procedure.scope.code,
                                                 ident: ident + 1,
                                                 contexts: contexts)
                    emitLocal(body)
                    emitLocal("}")
                }
                
            case let call as ProcedureCall:
                let (expCode, _) = getExpressionResult(call, ident: ident)
                emitLocal(expCode)
                
            case let variable as VariableDeclaration:
                
                if let literal = variable.expression as? StringLiteral {
                    guard let value = getCString(from: literal.value) else {
                        // @Todo: make sure we have to assert here
                        fatalError("Unsupported character in string literal. Only supporting ascii for now.")
                    }
                    stringLiterals[variable.id] = literal
                    emitGlobal("@\(variable.id) = private unnamed_addr constant [\(literal.value.count) x i8] c\"\(value)\"")
                }
                else {
                    let (expCode, expVal) = getExpressionResult(variable.expression!, ident: ident)
                    emitLocal(expCode)
                    // @Todo: support constant variables
                    // do it at ast building?
                    let type = matchType(variable.expType.name)
                    emitLocal("%\(variable.id) = alloca \(type)")
                    emitLocal("store \(type) \(expVal), \(type)* %\(variable.id)")
                }
                
            case let variable as VariableAssignment:
                let (expCode, expVal) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(expCode)
                let type = matchType(variable.expression.expType.name)
                emitLocal("store \(type) \(expVal), \(type)* %\(variable.receiverId)")
                
            case let ret as Return:
                let (expCode, expVal) = getExpressionResult(ret.value, ident: ident)
                emitLocal(expCode)
                emitLocal("ret \(matchType(ret.value.expType.name)) \(expVal)")
                
            default:
                fatalError("Undefined expression:\n\(expression)")
            }
        }
        
        return scope.trimmingCharacters(in: .newlines)
    }
    
    /// Remove % before label if it's unnamed, % is added later while emiting
    private func normalizeLabel(_ label: String) -> String {
        label.replacingOccurrences(of: "%", with: "")
    }
    
    /// Returns the latest loop context found (with a user label if specified)
    private func getLoopContext(from contexts: [StatementContext],
                                with userLabel: String?) -> LoopContext {
        
        if let userLabel = userLabel {
            guard let loopContext = contexts.last(where:
                { userLabel == ($0 as? LoopContext)?.userLabel }) as? LoopContext
                else { fatalError("Undefined break label \(userLabel)") }
            return loopContext
        }
        else {
            guard let loopContext = contexts.last(where:
                { $0 is LoopContext }) as? LoopContext
                else { fatalError("Can not break outside of loop context") }
            return loopContext
        }
    }
}
