//
//  StringBufferedReader.swift
//  HLSPlayer
//
//  Created by Jimmy on 2022/10/14.
//

import Foundation

open class StringBufferedReader: BufferedReader {
    private var buffer: [String]
    private var line: Int
    
    public init(data: String) {
        line = 0
        buffer = data.components(separatedBy: CharacterSet.newlines)
    }
    
    open func close() {}
    
    open func readLine() -> String? {
        if buffer.isEmpty || buffer.count <= line {
            return nil
        }
        let result = buffer[line]
        line += 1
        return result
    }
}
