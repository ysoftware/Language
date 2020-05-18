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
    
    private var stringLiterals: [String: StringLiteral] = [:]
    private var procedures: [String: ProcedureDeclaration] = [:]
    
    private var globalCounter = 0
    private var globalScope = ""
    
    private func count() -> Int {
        globalCounter += 1
        return globalCounter - 1
    }
    
    private func emitGlobal(_ string: String) {
        globalScope += string + "\n"
    }
    
    func generateIR(globalScope ast: Scope) -> String {
        let code = generate(inLocalScope: ast, ident: 0)
        return globalScope + "\n" + code
    }
    
    private func getProcedureArgumentString(from procedure: ProcedureDeclaration) -> String {
        var argumentNames = procedure.arguments.map(\.name).map(matchType)
        if procedure.flags.contains(.isVarargs) {
            argumentNames.append("...")
        }
        let arguments = argumentNames.joined(separator: ", ")
        return arguments
    }
    
    private func generate(inLocalScope ast: Scope, ident: Int) -> String {
        
        var scope = ""
        func emitLocal(_ string: String? = "") {
            guard let string = string else { return }
            let identation = String(repeating: "\t", count: ident)
            scope += "\(identation)\(string)\n"
        }
        
        for expression in ast.code {
            
            // PROCEDURE DECLARATION
            if let procedure = expression as? ProcedureDeclaration {

                let arguments = getProcedureArgumentString(from: procedure)
                let returnType = matchType(procedure.returnType.name)
                
                if procedure.flags.contains(.isForeign) {
                    
                    // @Todo: assert if not in global scope?
                    // do it at ast building
                    
                    guard procedure.code.isEmpty else {
                        report("Foreign procedures must not have a body")
                    }
                    emitGlobal("declare \(returnType) @\(procedure.name) (\(arguments))")
                }
                else {
                    emitLocal("define \(returnType) @\(procedure.name) (\(arguments)) {")
                    _ = count() // implicit entry block takes the next name
                    let body = generate(inLocalScope: procedure.code, ident: ident + 1)
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
                
                let ifBody = generate(inLocalScope: condition.block, ident: ident + 1)
                
                emitLocal()
                emitLocal("; %\(ifCount) if block")
                emitLocal(ifBody)
                emitLocal("br label %\(continueLabel)")

                if hasElse {
                    let elseBody = generate(inLocalScope: condition.elseBlock, ident: ident + 1)
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
            
            else if let variable = expression as? VariableAssignment {
                
                let (eCode, eValue) = getExpressionResult(variable.expression, ident: ident)
                emitLocal(eCode)
                
                let type = matchType(variable.expression.type.name)
                emitLocal("store \(type) \(eValue), \(type)* %\(variable.receiverId)")
            }
            
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
    
    private func getExpressionResult(
        _ expression: Expression, ident: Int) -> (code: String?, value: String) {
        let identation = String(repeating: "\t", count: ident)
        
        
        if let literal = expression as? IntLiteral {
            return (nil, "\(literal.value)")
        }
        
        else if let variable = expression as? Argument {
            return (nil, "%\(variable.name)")
        }
        
        else if let call = expression as? ProcedureCall {
            
            guard let procedure = procedures[call.name] else {
                report("Undefined procedure call: \(call.name)")
            }
            
            var code = "\n"
            var arguments: [String] = []
            
            // @Todo: dereference all arguments passed by value
            // for now, doing that manually
            
            // is there even such a thing? passing something by value?
            // in IR values are a completely different thing (SSA)
            
            for arg in call.arguments {
                
                code += "\(identation); argument \(arg.type.name)\n"
                
                if arg.type == .string {
                    
                    // @Todo: make it work with dynamic strings somehow
                    // I don't think we have to calculate its length before doing this?
                    // there has to be another way!
                    
                    // @Todo: make it work with all other references
                    // now this only works with references to constant string literals
                    // by 'hacky' keeping a list of those while parsing AST
                    
                    guard let literal = stringLiterals[arg.name] else {
                        report("Undefined symbol \(arg.name)")
                    }
                    
                    let argCount = count()
                    let length = literal.value.count
                    code += "\(identation)%\(argCount) = getelementptr [\(length) x i8], [\(length) x i8]* @\(literal.id), i32 0, i32 0"
                    
                    arguments.append("i8* %\(argCount)")
                }
                else {
                    let argCount = count()
                    let type = matchType(arg.type.name)
                    code += "\(identation)%\(argCount) = load \(type), \(type)* %\(arg.name)"
                    arguments.append("\(type) %\(argCount)")
                }
                
                code += "\n"
            }
            
            let returnType = matchType(procedure.returnType.name)
            let argValues = arguments.joined(separator: ", ")
            let argumentsString = getProcedureArgumentString(from: procedure)
            let resultCount = count()
            let value = "%\(resultCount)"
            
            code += "\(identation); procedure \(procedure.name)\n"
            code += "\(identation)\(value) = call \(returnType) (\(argumentsString)) @\(procedure.name) (\(argValues))"
            
            return (code, value)
        }
        
        else if let op = expression as? BinaryOperator {
                        
            // на примере add
            let type = matchType(op.type.name)
            let l = op.arguments.0
            let r = op.arguments.1
            
            let (leCode, leValue) = getExpressionResult(l, ident: ident)
            let (reCode, reValue) = getExpressionResult(r, ident: ident)
            
            // @Incomplete: this only takes pointers, doesn't work with int literals
            
            // these are identifiers or values (if literals)
            // passed to the operator
            var lCount = "", rCount = ""
            var loadL: String?, loadR: String?
            
            if l is IntLiteral {
                lCount = leValue
            }
            else {
                lCount = "%\(count())"
                loadL = "\(lCount) = load \(matchType(l.type.name)), \(matchType(l.type.name))* \(leValue)"
            }
            
            if r is IntLiteral {
                rCount = reValue
            }
            else {
                rCount = "%\(count())"
                loadR = "\(rCount) = load \(matchType(r.type.name)), \(matchType(r.type.name))* \(reValue)"
            }
            
            let resultCount = count()
            let result = "%\(resultCount) = \(op.name) \(type) \(lCount), \(rCount)"
            let value = "%\(resultCount)"
            
            var code = "\n"
            code += "\(identation); binary operator: \(op.name)\n"
            
            leCode.map { code += "\(identation)\($0)\n" }
            loadL.map { code += "\(identation)\($0)\n" }
            
            reCode.map { code += "\(identation)\($0)\n" }
            loadR.map { code += "\(identation)\($0)\n" }
            
            code += "\(identation)\(result)"
            
            return (code, value)
        }
        
        report("Unsupported expression\n\(expression)")
    }
}
