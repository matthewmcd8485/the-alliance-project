//
//  ApplicationUser.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/25/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

struct ApplicationUser {
    let firstName: String
    let lastName: String
    let email: String
    
    var safeEmail: String {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        return safeEmail.replacingOccurrences(of: "@", with: "-")
    }
}
