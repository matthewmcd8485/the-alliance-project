//
//  Result.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/27/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

struct PhotoResult: Codable {
    let id: String
    let urls: URLS
    let user: UnsplashUser
    let links: UnsplashLinks
}
