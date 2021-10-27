//
//  UnsplashUser.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/27/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

struct UnsplashUser: Codable {
    let name: String
    let id: String
    let username: String
    let links: ProfileURLs
}
