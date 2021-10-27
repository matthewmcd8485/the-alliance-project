//
//  APIResponse.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/27/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

struct APIResponse: Codable {
    let total: Int
    let total_pages: Int
    let results: [PhotoResult]
}
