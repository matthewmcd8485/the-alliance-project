//
//  DatabaseManager.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 10/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import FirebaseFirestore
import MessageKit
import CoreLocation

final class DatabaseManager {
    
    // Static reference to the class
    static let shared = DatabaseManager()
    
    private let firestore = Firestore.firestore()
    
    private let database = Database.database().reference()
    
    private var listener: ListenerRegistration?
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    // Adds a new user to the "Users" collection on Firestore
    // Adds a new user to the Realtime Databse as well
    public func insertUser(with user: ApplicationUser) {
        let fullName = user.firstName + " " + user.lastName
        firestore.collection("users").document(user.email).setData([
            
            "Full Name": fullName,
            "Email Address": user.email,
            "Username": "Username not set",
            "Instagram": "",
            "Twitter": "",
            "YouTube": "",
            "Website": "",
            "Locality": "Location not set",
            "Apple ID User Identifier": "Apple ID Not Used",
            "Profile Image URL": "No profile picture yet",
            "Firebase Cloud Messaging Token": "Notifications not set up yet"
            
        ])
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ])
    }
    
    // Determines whether a user already exists inside the Firestore "Users" collection
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        firestore.collection("users").whereField("Email Address", isEqualTo: email).getDocuments() { (QuerySnapshot, error) in
            if error != nil {
                print("Error reaching database: \(error!)")
            } else {
                if QuerySnapshot?.documents.count != 0 {
                    // Email already exists in the database
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Get All Users
    // Returns an array of dictionaries of all users of the app
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        var users = [[String: String]]()
        firestore.collection("users").getDocuments() { (snapshot, error) in
            if error != nil {
                print("Error grabbing users: \(error!)")
                completion(.failure(DatabaseError.failedToFetch))
            } else {
                for document in snapshot!.documents {
                    let data = document.data()
                    let name = data["Full Name"] as? String ?? ""
                    let email = data["Email Address"] as? String ?? ""
                    let fcmToken = data["Firebase Cloud Messaging Token"] as? String ?? ""
                    
                    let user = [
                        "name" : name,
                        "email" : email,
                        "fcmToken" : fcmToken
                    ]
                    
                    // Check if the user is blocked
                    if !ReportingManager.shared.userIsBlocked(for: email) {
                        users.append(user)
                    }
                }
                completion(.success(users))
            }
        }
    }
    
    // Checks the Firebase Auth status of an account and allows the app to log the user out if the account has been disabled.
    public func checkIfAccountIsDisabled(completion: @escaping (Bool) -> Void) {
        if let userInfo = Auth.auth().currentUser {
            userInfo.reload(completion: { (error) in
                guard error == nil else {
                    debugPrint(error.debugDescription)
                    completion(false)
                    return
                }
                completion(true)
            })
        }
    }
}

extension DatabaseManager {
    
    // MARK: - Create Conversation
    // Creates a new conversation within the "Conversations" subcollection of both users
    public func createNewConversation(with otherUserEmail: String, name: String, otherUserFcmToken: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.string(forKey: "email"), let currentName = UserDefaults.standard.string(forKey: "fullName"), let currentFcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            return
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = FormatDate.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        // Add conversation to user subcollection
        let otherUserName = UserDefaults.standard.string(forKey: "otherUserName")
        let conversationID = "conversation_\(firstMessage.messageId)"
        firestore.collection("users").document("\(currentEmail)").collection("conversations").document("\(conversationID)").setData([
            "Conversation ID" : conversationID,
            "Other User Email" : otherUserEmail,
            "Latest Message" : message,
            "Message Date" : dateString,
            "Name" : otherUserName!,
            "Other User FCM Token" : otherUserFcmToken,
            "Message Kind" : firstMessage.kind.messageKindString,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                completion(false)
                return
            }
        })
        
        // Add conversation to receipient's messages subcollection
        firestore.collection("users").document("\(otherUserEmail)").collection("conversations").document("\(conversationID)").setData([
            "Conversation ID" : conversationID,
            "Other User Email" : currentEmail,
            "Latest Message" : message,
            "Message Date" : dateString,
            "Other User FCM Token" : currentFcmToken,
            "Name" : currentName,
            "Message Kind" : firstMessage.kind.messageKindString,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                completion(false)
                return
            }
        })
        
        finishCreatingConversation(conversationID: conversationID, name: currentName, fcmToken: otherUserFcmToken, firstMessage: firstMessage, completion: completion)
    }
    
    // MARK: - Finish Creating Conversation
    // Adds the conversation's first message to the "Messages" collection on Firestore
    private func finishCreatingConversation(conversationID: String, name: String, fcmToken: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        var message = ""
        
        let messageDate = firstMessage.sentDate
        let dateString = FormatDate.dateFormatter.string(from: messageDate)
        
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email"), let senderToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            completion(false)
            return
        }
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        firestore.collection("messages").document("\(conversationID)").setData([
            "Conversation ID" : conversationID,
            "Sent Date" : dateString,
            "Sender Email" : currentUserEmail,
            "Sender Name" : name,
            "Is Read" : false
        ], merge: true, completion: { [weak self] error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                completion(false)
                return
            }
            strongSelf.firestore.collection("messages").document("\(conversationID)").collection("messages").document("\(firstMessage.messageId)").setData([
                "Message ID" : firstMessage.messageId,
                "Message Type" : firstMessage.kind.messageKindString,
                "Sender Email" : currentUserEmail,
                "Content" : message,
                "Sent Date" : dateString,
                "Sender FCM Token" : senderToken,
                "Is Read" : false
            ], merge: true, completion: { error in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                var body = message
                if firstMessage.kind.messageKindString == "photo" {
                    body = "Attachment: 1 Photo"
                } else if firstMessage.kind.messageKindString == "video" {
                    body = "Attachment: 1 Video"
                } else if firstMessage.kind.messageKindString == "location" {
                    body = "Attachment: 1 Location"
                } else {
                    
                }
                
                // Sending a notification
                let sender = PushNotificationSender()
                sender.sendPushNotification(to: fcmToken, title: name, body: body)
                completion(true)
            })
        })
    }
    
    // Finds and returns the other user's full name
    public func retrieveOtherUsersName(with email: String) -> String {
        var name = ""
        firestore.collection("users").whereField("Email Address", isEqualTo: email).getDocuments() { (snapshot, error) in
            if error != nil {
                print("Error grabbing users: \(error!)")
            } else {
                for document in snapshot!.documents {
                    let data = document.data()
                    name = data["Full Name"] as? String ?? ""
                }
            }
        }
        return name
    }
    
    // MARK: - Get All Conversations
    // Returns an array of conversation objects for a given user
    public func getAllConversations(for email: String, currentConversations: [Conversation], completion: @escaping (Result<[Conversation], Error>) -> Void) {
        var conversations: [Conversation] = []
        firestore.collection("users").document("\(email)").collection("conversations").addSnapshotListener { (QuerySnapshot, error) in
            guard error == nil else {
                print("Error listening to conversation document changes: \(error!)")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            for document in QuerySnapshot!.documents {
                let data = document.data()
                
                let id = data["Conversation ID"] as? String ?? ""
                let name = data["Name"] as? String ?? ""
                let otherUserEmail = data["Other User Email"] as? String ?? ""
                let date = data["Message Date"] as? String ?? ""
                let text = data["Latest Message"] as? String ?? ""
                let isRead = data["Is Read"] as? Bool ?? false
                let token = data["Other User FCM Token"] as? String ?? ""
                let type = data["Message Kind"] as? String ?? ""
                
                print("Latest message: \(text)")
                
                var kind: ReceivedMessageKind?
                if type == "photo" {
                    kind = .photo
                } else if type == "video" {
                    kind = .video
                } else if type == "location" {
                    kind = .location
                } else {
                    kind = .text
                }
                
                guard let finalKind = kind else {
                    return
                }
                
                print(date)
                
                let latestMessage = LatestMessage(date: date, text: text, isRead: isRead, kind: finalKind)
                let conversation = Conversation(conversationID: id, name: name, otherUserEmail: otherUserEmail, fcmToken: token, latestMessage: latestMessage)
                
                // Check if the user is blocked
                if !ReportingManager.shared.userIsBlocked(for: otherUserEmail) {
                    conversations.append(conversation)
                }
            }
            
           conversations.sort {
               FormatDate.dateFormatter.date(from: $0.latestMessage.date)! > FormatDate.dateFormatter.date(from: $1.latestMessage.date)!
           }
            
            
            let filteredConversations = conversations.filterDuplicates { $0.conversationID == $1.conversationID }
            completion(.success(filteredConversations))
        }
    }
    
    // MARK: - Get All Messages
    // Returns an array of messages for a given conversation
    public func getAllMessagesForConversation(with id: String, currentMessages: [Message], completion: @escaping (Result<[Message], Error>) -> Void) {
        var messages = currentMessages
        firestore.collection("messages").document(id).collection("messages").getDocuments() { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            for document in snapshot.documents {
                
                let sentDate = document.get("Sent Date") as? String ?? ""
                let messageID = document.get("Message ID") as? String ?? ""
                let senderID = document.get("Sender Email") as? String ?? ""
                let content = document.get("Content") as? String ?? ""
                let type = document.get("Message Type") as? String ?? ""
                
                let date = FormatDate.dateFormatter.date(from: sentDate)
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageURL = URL(string: content), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: imageURL, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let videoURL = URL(string: content), let placeholder = UIImage(systemName: "play.rectangle.fill")?.withTintColor(UIColor(named: "purpleColor")!, renderingMode: .alwaysOriginal) else {
                        return
                    }
                    
                    // if i want a thumbnail, i need to change the "placeholder"
                    let media = Media(url: videoURL, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]), let latitude = Double(locationComponents[1]) else {
                        return
                    }
                    
                    print("Rendering location... Latitude = \(latitude), Longitude = \(longitude)")
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                } else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return
                }
                
                let sender = Sender(photoURL: "", senderId: senderID, displayName: "")
                let message = Message(sender: sender, messageId: messageID, sentDate: date ?? Date(), kind: finalKind)
                
                messages.append(message)
            }
            
            let filteredMessages = messages.filterDuplicates { $0.messageId == $1.messageId }
            completion(.success(filteredMessages))
        }
    }
    
    // MARK: - Listen For Messages
    // Listens for new messages between two users
    public func listenForNewMessages(with id: String, currentMessages: [Message], completion: @escaping (Result<[Message], Error>) -> Void) {
        var messages = currentMessages
        listener = firestore.collection("messages").document(id).collection("messages").addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                completion(.failure(DatabaseError.failedToListen))
                return
            }
            
            snapshot.documentChanges.forEach { change in
                switch change.type {
                case .added:
                    let document = change.document
                    
                    let sentDate = document.get("Sent Date") as? String ?? ""
                    let messageID = document.get("Message ID") as? String ?? ""
                    let senderID = document.get("Sender Email") as? String ?? ""
                    let content = document.get("Content") as? String ?? ""
                    
                    let date = FormatDate.dateFormatter.date(from: sentDate)
                    
                    let sender = Sender(photoURL: "", senderId: senderID, displayName: "")
                    let message = Message(sender: sender, messageId: messageID, sentDate: date ?? Date(), kind: .text(content))
                    
                    messages.append(message)
                default:
                    break
                }
            }
            let filteredMessages = messages.filterDuplicates { $0.messageId == $1.messageId }
            completion(.success(filteredMessages))
        }
    }
    
    // MARK: - Send Message
    // Sends a message between two users
    public func sendMessage(to conversationID: String, recepientEmail: String, recepientFcmToken: String, recepientName: String, NewMessage: Message, completion: @escaping (Bool) -> Void) {
        
        //Firestore.enableLogging(true)
        
        var message = ""
        
        let senderFcmToken = UserDefaults.standard.string(forKey: "fcmToken")
        
        var step1 = false
        var step2 = false
        var step3 = false
        var step4 = false
        
        switch NewMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let targetURLString = mediaItem.url?.absoluteString {
                message = targetURLString
            }
        case .video(let mediaItem):
            if let targetURLString = mediaItem.url?.absoluteString {
                message = targetURLString
            }
        case .location(let locationData):
            let location = locationData.location
            message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let date = NewMessage.sentDate
        let dateString = FormatDate.dateFormatter.string(from: date)
        let currentName = UserDefaults.standard.string(forKey: "fullName")
        let currentEmail = UserDefaults.standard.string(forKey: "email")
        
        // Add message to current user's messages subcollection
        firestore.collection("users").document("\(currentEmail!)").collection("conversations").document("\(conversationID)").setData([
            "Latest Message" : message,
            "Conversation ID" : conversationID,
            "Message Date" : dateString,
            "Name" : recepientName,
            "Other User Email": recepientEmail,
            "Other User FCM Token" : recepientFcmToken,
            "Message Kind" : NewMessage.kind.messageKindString,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                print("error with step 1: \(error!)")
                completion(false)
                return
            }
            print("Step 1 completed!")
            step1 = true
        })
        
        // Add message to receipient's messages subcollection
        firestore.collection("users").document("\(recepientEmail)").collection("conversations").document("\(conversationID)").setData([
            "Latest Message" : message,
            "Conversation ID" : conversationID,
            "Message Date" : dateString,
            "Name" : currentName!,
            "Other User Email": currentEmail!,
            "Other User FCM Token" : senderFcmToken!,
            "Message Kind" : NewMessage.kind.messageKindString,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                print("error with step 2: \(error!)")
                completion(false)
                return
            }
            print("Step 2 completed!")
            step2 = true
        })
        
        // Update messages collection conversation document
        firestore.collection("messages").document("\(conversationID)").setData([
            "Message Date" : dateString,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                print("error with step 3: \(error!)")
                completion(false)
                return
            }
            print("Step 3 completed!")
            step3 = true
        })
        
        // Update message subcollection
        firestore.collection("messages").document("\(conversationID)").collection("messages").document(NewMessage.messageId).setData([
            "Message ID" : NewMessage.messageId,
            "Message Type" : NewMessage.kind.messageKindString,
            "Sender Email" : currentEmail!,
            "Content" : message,
            "Sent Date" : dateString,
            "Sender FCM Token" : senderFcmToken!,
            "Is Read" : false
        ], merge: true, completion: { error in
            guard error == nil else {
                print("error with step 4: \(error!)")
                completion(false)
                return
            }
            print("Step 4 completed!")
            step4 = true
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if step1 && step2 && step3 && step4 {
                var body = ""
                if NewMessage.kind.messageKindString == "photo" {
                    body = "Attachment: 1 Photo"
                } else if NewMessage.kind.messageKindString == "video" {
                    body = "Attachment: 1 Video"
                } else if NewMessage.kind.messageKindString == "location" {
                    body = "Attachment: 1 Location"
                } else {
                    body = message
                }
                
                // Sending a notification
                let sender = PushNotificationSender()
                sender.sendPushNotification(to: recepientFcmToken, title: currentName!, body: body)
                completion(true)
            } else {
                completion(false)
            }
        }
        
    }
    
    // MARK: - Delete Conversation
    // Deletes a conversation from a user's "Conversations" subcollection
    // NOTE - this does not delete the conversation from the other user, nor does it delete the messages they sent
    public func deleteConversation(conversationID: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        print("Deleting conversation with ID: \(conversationID)")
        firestore.collection("users").document(email).collection("conversations").document(conversationID).delete() { error in
            guard error == nil else {
                print("Error deleting conversation: \(error!)")
                completion(false)
                return
            }
            print("Conversation deleted!")
            completion(true)
        }
    }
    
    // MARK: - Conversation Exists
    // Checks whether a conversation already exists between two users
    public func conversationExists(with targetEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let senderEmail = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        
        firestore.collection("users").document(targetEmail).collection("conversations").whereField("Other User Email", isEqualTo: senderEmail).getDocuments() { snapshot, error in
            guard error == nil else {
                print("Error finding conversations: \(error!)")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            if let conversation = snapshot!.documents.first(where: {
                guard let targetSender = $0["Other User Email"] as? String else {
                    return false
                }
                return senderEmail == targetSender
            }) {
                // get ID
                guard let id = conversation.data()["Conversation ID"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
}

// MARK: - Blocking Users
extension DatabaseManager {
    // Adds an external user's email to the current user's "Blocked Users" subcollection
    public func blockUser(with emailToBlock: String, completion: @escaping (Bool) -> Void) {
        
        // Update local cache of blocked users
        var blockedUsers = UserDefaults.standard.stringArray(forKey: "blockedUsers") ?? [""]
        blockedUsers.append(emailToBlock)
        UserDefaults.standard.set(blockedUsers, forKey: "blockedUsers")
        
        // Update Firestore collection of blocked users
        let email = UserDefaults.standard.string(forKey: "email")
        let date = FormatDate.dateFormatter.string(from: Date())
        firestore.collection("users").document(email!).collection("blocked users").document(emailToBlock).setData([
            "Email Address" : emailToBlock,
            "Blocked On" : date
        ], merge: true, completion: { error in
            guard error == nil else {
                print("Error blocking user: \(error!)")
                completion(false)
                return
            }
            print("User blocked!")
            completion(true)
        })
    }
    
    // Updates a cached array of all blocked users for a given user
    public func updateBlockedUsersList(for email: String, completion: @escaping (Bool) -> Void) {
        
        let email = UserDefaults.standard.string(forKey: "email")
        var blockedUsers: [String] = [""]
        firestore.collection("users").document(email!).collection("blocked users").getDocuments() { (snapshot, error) in
            guard error == nil else {
                print("Error accessing blocked users subcollection: \(error!)")
                return
            }
            
            // If the array is empty, there are no blocked users
            guard !snapshot!.isEmpty else {
                UserDefaults.standard.set([""], forKey: "blockedUsers")
                completion(false)
                return
            }
            
            for document in snapshot!.documents {
                let blockedUserEmail = document.get("Email Address") as! String
                blockedUsers.append(blockedUserEmail)
            }
            
            UserDefaults.standard.set(blockedUsers, forKey: "blockedUsers")
            completion(true)
        }
    }
}
