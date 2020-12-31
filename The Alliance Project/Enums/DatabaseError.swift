//
//  DatabaseError.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/25/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

public enum DatabaseError: Error {
    case failedToFetch
    case failedToListen
    case failedToWrite
}
