//
//  ReportingManager.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import Firebase

final class ReportingManager {
    
    static let shared = ReportingManager()
    
    let firestore = Firestore.firestore()
    
    // Checks a cached array to see if a particular user is blocked
    public func userIsBlocked(for email: String) -> Bool {
        let blockedUsers = UserDefaults.standard.stringArray(forKey: "blockedUsers") ?? [""]
        
        guard !blockedUsers.isEmpty, blockedUsers[0] != "" else {
            return false
        }
        
        if let blockedUser = blockedUsers.first(where: { $0 == email }) {
            print("\(blockedUser) is blocked; removing this user from results.")
            return true
        }
        
        return false
    }
    
    // Adds an external user's project to a "Reported Projects" collection on Firestore
    public func reportProject(with email: String, title: String, description: String, date: String, kind: String, completion: @escaping (Bool) -> Void) {
        firestore.collection("reported projects").document("\(title)_\(email)_\(date)").setData([
            "User Email" : email,
            "Reported Date" : date,
            "Project Title" : title,
            "Project Description" : description,
            "Report Type" : kind
        ], merge: true, completion: { error in
            guard error == nil else {
                print("Error reporting project: \(error!)")
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    // Adds an external user's account to a "Reported Users" collection on Firestore
    public func reportUser(with email: String, name: String, date: String, kind: String, completion: @escaping (Bool) -> Void) {
        firestore.collection("reported users").document("\(email)_\(date)").setData([
            "User Email" : email,
            "Reported Date" : date,
            "User Name" : name,
            "Report Type" : kind
        ], merge: false, completion: { error in
            guard error == nil else {
                print("Error reporting user: \(error!)")
                completion(false)
                return
            }
            completion(true)
        })
    }
}
