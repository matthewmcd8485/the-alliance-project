//
//  LatestMessage.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import MessageKit

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
    let kind: ReceivedMessageKind
}
