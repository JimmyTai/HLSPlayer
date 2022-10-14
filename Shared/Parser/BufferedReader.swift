//
//  BufferedReader.swift
//  HLSPlayer
//
//  Created by Jimmy on 2022/10/14.
//

import Foundation

public protocol BufferedReader {
    func close()
    
    func readLine() -> String?
}
