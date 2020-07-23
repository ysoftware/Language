//
//  ConstSizeArray.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 23.07.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

final class ConstantSizeArray<T: Equatable>: ExpressibleByArrayLiteral, Equatable {

    init(_ slice: Slice<ConstantSizeArray<T>>) {
        count = slice.count
        memory = UnsafeMutableBufferPointer.allocate(capacity: Swift.max(count, 100) + 1)
        _ = memory.initialize(from: slice)
    }

    static func == (lhs: ConstantSizeArray<T>, rhs: ConstantSizeArray<T>) -> Bool {
        if lhs.count != rhs.count { return false }
        for i in 0..<lhs.count {
            if lhs[i] != rhs[i] { return false }
        }
        return true
    }

    typealias ArrayLiteralElement = T

    private(set) var count = 0
    let memory: UnsafeMutableBufferPointer<T>

    var length: Int {
        return memory.count
    }

    private init(_ count: Int) {
        memory = UnsafeMutableBufferPointer.allocate(capacity: Swift.max(count, 100) + 1)
        self.count = count
    }

    convenience init(count: Int, repeating value: T) {
        self.init(count)
        memory.initialize(repeating: value)
    }

    required convenience init(arrayLiteral: ArrayLiteralElement...) {
        self.init(arrayLiteral.count)
        _ = memory.initialize(from: arrayLiteral)
    }

    func reset() {
        count = 0
        memset(memory.baseAddress, 0, 1) // @Robustness: we don't care to clean the whole memory here
    }

    var last: T {
        memory[count-1]
    }

    func append(contentsOf constArray: ConstantSizeArray<T>) {
        memcpy(memory.baseAddress?.advanced(by: count * MemoryLayout<T>.stride),
               constArray.memory.baseAddress,
               constArray.count * MemoryLayout<T>.stride)
        count += constArray.count
    }

    @inline(__always)
    func append(_ value: T) {
        memory[count] = value
        count += 1
    }

    deinit {
        memory.deallocate()
    }

    subscript(index: Int) -> T {
        set(value) {
            memory[index] = value
        }
        get {
            return memory[index]
        }
    }
}

extension ConstantSizeArray: MutableCollection {

    var startIndex: Int {
        return 0
    }

    var endIndex: Int {
        return count
    }

    func index(after i: Int) -> Int {
        return i + 1
    }
}

extension ConstantSizeArray where ArrayLiteralElement == CChar {

    var print: String {
        var a: [CChar] = []
        for i in 0..<count {
            a.append(self[i])
        }
        let string = String(cString: a + [0])
        return string
    }

    var printAll: String {
        var a: [CChar] = []
        for i in 0..<length {
            a.append(self[i])
        }
        let string = String(cString: a + [0])
        return string
    }
}
