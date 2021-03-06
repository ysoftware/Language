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
        character -= count // @Todo: what if it's 0?
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

func report(_ error: String, _ range: CursorRange? = nil, proc: String = #function, ln: Int = #line) -> Never {
    let position = range.map { " around \($0.start)" } ?? ""
    print("Internal Error\(position): \(error)")
    print("Context: \(proc)#\(ln)")
    quit(1)
}
