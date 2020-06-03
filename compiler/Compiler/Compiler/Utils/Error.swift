//
//  Error.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct Cursor: Equatable, CustomDebugStringConvertible {
    
    var debugDescription: String {
        "\(lineNumber):\(character)"
    }
    
    var lineNumber: Int
    var character: Int
    
    init(lineNumber: Int = 1, character: Int = 0) {
        self.lineNumber = lineNumber
        self.character = character
    }
    
    func advancingCharacter() -> Cursor {
        var next = self
        next.advanceCharacter()
        return next
    }
    
    mutating func advanceCharacter(by count: Int = 1) {
        character += count
    }
    
    mutating func advanceLine() {
        character = 0
        lineNumber += 1
    }
    
    static func ==(lhs: Cursor, rhs: Cursor) -> Bool {
        lhs.lineNumber == rhs.lineNumber && lhs.character == rhs.character
    }
}

func report(_ error: String,
            in file: String = "",
            lineNumber: String = ""
) -> Never {
    
    print("Error: \(error)")
    exit(1)
}
