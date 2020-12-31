//
//  Sender.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import MessageKit

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}
