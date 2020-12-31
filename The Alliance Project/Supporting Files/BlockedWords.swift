//
//  BlockedWords.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/25/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

final class BlockedWords {
    
    public func blockedWords() -> [String] {
        var blockedWords: [String] = []
        if let path = Bundle.main.path(forResource: "Blocked Words List", ofType: "txt") {
            do {
                let list = try String(contentsOfFile: path, encoding: .utf8)
                blockedWords = list.components(separatedBy: ", ")
            } catch let error {
                print("Error finding list: \(error)")
            }
        }
        return blockedWords
    }
    
    static let shared = BlockedWords()
    
}
