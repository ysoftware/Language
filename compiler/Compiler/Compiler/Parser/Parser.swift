//
//  Parser.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 20.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func parse(filename: String? = nil, _ tokens: [Token]) -> Result<Scope, ParserError> {

    func parseExpression(_ expression: Expression) {
        
    }

    return .failure(ParserError(.notImplemented))
}
