//
//  Utils.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 22.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

extension String {
    
    func endIndex(offsetBy offset: Int) -> String.Index { index(endIndex, offsetBy: offset) }
    func startIndex(offsetBy offset: Int) -> String.Index { index(startIndex, offsetBy: offset) }
    subscript(index: Int) -> Character { self[startIndex(offsetBy: index)] }
}