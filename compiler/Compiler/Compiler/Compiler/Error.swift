//
//  Error.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Cursor {
    
    let filename: String
    var lineNumber: Int
    var character: Int
    
    init(filename: String = "") {
        self.filename = filename
        self.lineNumber = 1
        self.character = 0
    }
    
    mutating func advanceCharacter(by count: Int = 1) {
        character += count
    }
    
    mutating func advanceLine() {
        character = 0
        lineNumber += 1
    }
}

func report(_ error: String,
            in file: String = "",
            lineNumber: String = ""
) -> Never {
    
    print("Error: \(error)")
    exit(1)
}
