//
//  User.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

extension User: CustomDebugStringConvertible {
    var debugDescription: String {
        return """
        ID: \(id)
        Full Name: \(firstName) \(lastName)
        Email: \(email)
        """
    }
}
