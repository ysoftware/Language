//
//  ParserModel.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 24.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct ParserError: Error {
    
    enum Message: String, Equatable {
        
        case notImplemented = "Not implemented"
    }
    
    let fileName: String?
    let cursor: Cursor
    let message: Message
    
    init(_ message: Message) {
        self.cursor = Cursor()
        self.message = message
        self.fileName = nil
    }
    
    init(fileName: String? = nil, cursor: Cursor, _ message: Message) {
        self.message = message
        self.cursor = cursor
        self.fileName = fileName
    }
}
