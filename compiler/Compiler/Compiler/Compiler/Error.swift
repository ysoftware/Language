//
//  Error.swift
//  Compiler
//
//  Created by Ерохин Ярослав Игоревич on 17.05.2020.
//  Copyright © 2020 Yaroslav Erokhin. All rights reserved.
//

import Foundation

func report(_ error: String,
            in file: String = "",
            lineNumber: String = ""
) -> Never {
    
    print("Error: \(error)")
    exit(1)
}
