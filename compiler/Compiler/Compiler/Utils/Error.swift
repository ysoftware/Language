//
//  Error.swift
//  Compiler
//
//  Created by Yaroslav Erokhin on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

struct CursorRange: Equatable, CustomDebugStringConvertible {

    var start: Cursor
    var end: Cursor

    var debugDescription: String {
        "\(start)-\(end)"
    }

    init() {
        self.start = Cursor()
        self.end = Cursor()
    }

    init(_ start: Cursor, _ end: Cursor) {
        self.start = start
        self.end = end
    }
}

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
    
    func advancingCharacter(by count: Int = 1) -> Cursor {
        var next = self
        next.advanceCharacter(by: count)
        return next
    }
    
    func withdrawingCharacter() -> Cursor {
        var next = self
        next.withdrawCharacter()
        return next
    }
    
    mutating func withdrawCharacter(by count: Int = 1) {
        character -= count
    }
    
    mutating func advanceCharacter(by count: Int = 1) {
        character += count
    }
    
    mutating func advanceLine() {
        character = 0
        lineNumber += 1
    }
    
    static func isDefault(_ cursor: Cursor) -> Bool {
        let def = Cursor()
        return cursor.lineNumber == def.lineNumber
            && cursor.character == def.character
    }
    
    static func ==(lhs: Cursor, rhs: Cursor) -> Bool {
        if isDefault(lhs) || isDefault(rhs) { return true }
        return lhs.lineNumber == rhs.lineNumber && lhs.character == rhs.character
    }
}

func report(_ error: String, _ range: CursorRange? = nil, fl: String = #file, ln: Int = #line) -> Never {
    report(error, range?.start, range?.end, fl: fl, ln: ln)
}

// @Todo: refactor this to single point of error reporting
func report(_ error: String, _ start: Cursor? = nil, _ end: Cursor? = nil, fl: String = #file, ln: Int = #line) -> Never {
    
    print("Internal Error: \(error)")
    print("Context: \(fl) #\(ln)")
    quit(1)
}
