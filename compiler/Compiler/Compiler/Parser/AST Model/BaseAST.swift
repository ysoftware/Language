//
//  BaseAST.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

protocol Copying {
    func makeCopy() -> Self
}

extension Array: Copying where Element: Copying {
    func makeCopy() -> Array<Element> { map { $0.makeCopy() }}
}

final class Code: Ast, Equatable, Copying {
    
    var isRValue: Bool  { false }
    var range: CursorRange

    static func == (lhs: Code, rhs: Code) -> Bool {
        lhs.statements.elementsEqual(rhs.statements) { $0.equals(to: $1) }
    }
    
    var debugDescription: String {
        var string = "[Scope] \(statements.count) statement\(plural(statements.count))"
        for statement in statements {
            string.append("\n    \(statement.debugDescription)")
        }
        return string
    }
    
    var statements: [Statement]
    
    static let empty = Code([])
    var isEmpty: Bool { statements.isEmpty }
    
    internal init(_ code: [Statement]) {
        self.statements = code
        self.range = CursorRange()
    }

    func makeCopy() -> Code {
        let statms = statements.map { ($0 as Copying).makeCopy() } as! [Statement]
        return Code(statms)
    }
}

protocol Ast: class, CustomDebugStringConvertible, Copying {
    var range: CursorRange { get set }
    var isRValue: Bool { get }
}

protocol Statement: Ast { }

protocol Expression: Ast {
    
    var exprType: Type { get set }
}

protocol Declaration: Statement {
    var ood: Int { get }
    var name: String { get }
    var id: String { get }
}

protocol LiteralExpr: Expression {
    var exprType: Type { get set }
}
