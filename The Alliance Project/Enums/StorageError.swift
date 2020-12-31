//
//  StorageError.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadURL
}
