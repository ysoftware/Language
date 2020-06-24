//
//  IRGen.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class IR {
    
    internal var stringLiterals: [String: StringLiteral] = [:]
    internal var procedures: [String: ProcedureDeclaration] = [:]
    internal var structures: [String: StructDeclaration] = [:]

    internal var globalCounter = 0
    internal var globalScope = ""
    
    /// Use this to generate LLVM IR code
    func generateIR(globalScope ast: Code) -> String {
        let code = processStatements(ast.statements, indentLevel: 0, contexts: [])
        return globalScope + "\n" + code
    }
    
    /// Returns the current counter value, also advances it for the next time
    internal func count() -> Int {
        defer { globalCounter += 1 }
        return globalCounter
    }
    
    /// Write a line of IR text into the global scope
    internal func emitGlobal(_ string: String) {
        if string.isEmpty { globalScope += "\n" }
        else { globalScope += "\(string)\n" }
    }
    
    /// Process statements and return IR text
    private func processStatements(_ statements: [Statement],
                                   indentLevel: Int = 1,
                                   contexts: [StatementContext]) -> String {
        
        var code = ""
        /// Write a line of IR text into the local scope
        func emitLocal(_ string: String? = "") {
            guard let string = string else { return }
            if string.isEmpty { code += "\n" }
            else { code += indentString(string, level: indentLevel) + "\n" }
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
                
                let (expCode, expVal) = getExpressionResult(loop.condition)
                emitLocal()
                emitLocal("br label %\(counter) ; terminating previous block")
                emitLocal()
                emitLocal("; %\(counter) loop.\(counter).condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(bodyLabel), label %\(continueLabel)")
                
                let loopBody = processStatements(loop.block.statements,
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
                let (expCode, expVal) = getExpressionResult(condition.condition)
                
                let counter = count()
                let bodyLabel = "; %\(counter) if.\(counter).body"
                let continueLabel = "if.\(counter).continue"
                let elseLabel = hasElse ? "if.\(counter).else" : continueLabel
                
                emitLocal()
                emitLocal("; if condition")
                emitLocal(expCode)
                emitLocal("br i1 \(expVal), label %\(counter), label %\(elseLabel)")
                
                let ifBody = processStatements(condition.block.statements, contexts: contexts)
                emitLocal()
                emitLocal("\(bodyLabel):")
                emitLocal(ifBody)
                emitLocal("br label %\(continueLabel)")
                
                if hasElse {
                    let elseBody = processStatements(condition.elseBlock.statements, contexts: contexts)
                    emitLocal()
                    emitLocal("\(elseLabel):")
                    emitLocal(elseBody)
                    emitLocal("br label %\(continueLabel) ; exiting else.\(counter)")
                }
                
                emitLocal()
                emitLocal("\(continueLabel):")
                
            case let structure as StructDeclaration:
                
                structures[structure.name] = structure
                
                emitGlobal("")
                emitGlobal("; struct decl: \(structure.name)")
                emitGlobal("%\(structure.name)__struct = type { \(structure.members.map { matchType($0.exprType) }.joined(separator: ", ")) }")
                
            case let procedure as ProcedureDeclaration:
                globalCounter = 0
                procedures[procedure.id] = procedure
                let arguments = getProcedureArgumentString(from: procedure, printName: false)
                let returnType = matchType(procedure.returnType)
                
                if procedure.flags.contains(.isForeign) {
                    emitGlobal("declare \(returnType) @\(procedure.name) (\(arguments))")
                }
                else {
                    emitLocal("define \(returnType) @\(procedure.name) (\(arguments)) {")
                    
                    if procedure.arguments.count > 0 {
                        for arg in procedure.arguments {
                            let argValue = "%\(count())"
                            
                            let argString = """
                            ; procedure arguments
                            %\(arg.name) = alloca \(matchType(arg.exprType))
                            store \(matchType(arg.exprType)) \(argValue), \(matchType(arg.exprType))* %\(arg.name)
                            """
                            emitLocal(indentString(argString, level: 1))
                        }
                        emitLocal()
                    }
                    
                    _ = count() // implicit entry block takes the next name
                    let body = processStatements(procedure.scope.statements, contexts: contexts)
                    emitLocal(body.trimmingCharacters(in: .newlines))
                    emitLocal("}\n")
                }
                
            case let call as ProcedureCall:
                let (expCode, _) = getExpressionResult(call)
                emitLocal(expCode)
                
            case let variable as VariableDeclaration:
                
                if let literal = variable.expression as? StringLiteral {
                    guard let value = getCString(from: literal.value) else {
                        // @Todo: make sure we have to assert here
                        report("Unsupported character in string literal. Only supporting ascii for now.")
                    }
                    stringLiterals[variable.name] = literal
                    // @Todo: properly check null termination for strings
                    emitGlobal("@\(variable.name) = private unnamed_addr constant [\(literal.value.count + 1) x i8] c\"\(value)\"")
                }
                else {
                    emitLocal("; declaration of \(variable.name)")
                    let type = matchType(variable.exprType)
                    emitLocal("%\(variable.name) = alloca \(type)")
                    
                    if let expression = variable.expression {
                        let (expCode, expVal) = getExpressionResult(expression)
                        emitLocal(expCode)
                        emitLocal("store \(type) \(expVal), \(type)* %\(variable.name)")
                    }
                    else {
                        emitLocal("store \(type) zeroinitializer, \(type)* %\(variable.name)")
                    }
                }
                
            case let assign as Assignment:
                
                emitLocal()
                emitLocal("; assignment")
                
                var receiver = ""
                if let value = assign.receiver as? Value {
                    receiver = "%\(value.name)" // @Todo: id for different scopes
                }
                else if let access = assign.receiver as? MemberAccess {
                    // this is rValue member access, IRGen for member value as expression is in another place
                    
                    let (intermediateCode, memberPointerValue) = getMemberPointerAddress(of: access)
                    emitLocal(intermediateCode)
                    receiver = memberPointerValue
                }
                else { report("Unsupported rValue.") }
                
                let (expCode, expVal) = getExpressionResult(assign.expression)
                emitLocal(expCode)
                let type = matchType(assign.expression.exprType)
                emitLocal("store \(type) \(expVal), \(type)* \(receiver)")
                
            case let ret as Return:
                let (expCode, expVal) = getExpressionResult(ret.value)
                emitLocal()
                emitLocal(expCode)
                if expVal == "void" { emitLocal("ret void") }
                else { emitLocal("ret \(matchType(ret.value.exprType)) \(expVal)") }
                
            default:
                report("Undefined expression:\n\(expression)")
            }
        }
        
        return code
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
                else { report("Undefined break label \(userLabel)") }
            return loopContext
        }
        else {
            guard let loopContext = contexts.last(where:
                { $0 is LoopContext }) as? LoopContext
                else { report("Can not break outside of loop context") }
            return loopContext
        }
    }
}
