//
//  ProfanityManager.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/16/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

final class ProfanityManager {
    
    static let shared = ProfanityManager()
    
    // Returns a list of blocked words in the "Blocked Words List.txt" file
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
    
    // Checks for profanity within a string
    // Returns false when no bad language is found, true when it is found
    public func checkForProfanity(in text: String) -> Bool {
        let blockedWords = self.blockedWords()
        guard !blockedWords.isEmpty else {
            return true
        }
                
        // Check the string for bad words in the array
        var stringContainsProfanity = false
        
        let array = text.components(separatedBy: " ")
        for badWord in blockedWords {
            for word in array {
                if word.lowercased() == badWord {
                    stringContainsProfanity = true
                }
            }
        }
        
        if stringContainsProfanity {
            return true
        }
        
        return false
    }
}
