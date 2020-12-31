//
//  Conversation.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation

struct Conversation {
    let conversationID: String
    let name: String
    let otherUserEmail: String
    let fcmToken: String
    let latestMessage: LatestMessage
}
