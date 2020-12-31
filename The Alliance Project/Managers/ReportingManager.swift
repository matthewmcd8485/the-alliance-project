//
//  ReportingManager.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

final class ReportingManager {
    static let shared = ReportingManager()
    
    public func userIsBlocked(for email: String) -> Bool {
        let blockedUsers = UserDefaults.standard.stringArray(forKey: "blockedUsers") ?? [""]
        
        guard !blockedUsers.isEmpty else {
            return false
        }
        
        if let blockedUser = blockedUsers.first(where: { $0 == email }) {
            print("\(blockedUser) is blocked; removing this user from results.")
            return true
        }
        
        return false
    }
}
