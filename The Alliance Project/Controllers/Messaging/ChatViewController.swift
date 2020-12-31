//
//  ChatViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/14/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Foundation
import FirebaseMessaging
import Firebase
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
import MapKit

class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    let alertManager = AlertManager.shared
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private var conversationID: String?
    private let otherUserFcmToken: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return nil
        }
        
        let name = UserDefaults.standard.string(forKey: "fullName")
        return Sender(photoURL: "", senderId: email, displayName: name!)
    }
    
    init(with email: String, id: String?, fcmToken: String?) {
        self.conversationID = id
        self.otherUserFcmToken = fcmToken
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        messageInputBar.sendButton.setTitleColor(UIColor(named: "purpleColor"), for: .normal)
        messageInputBar.inputTextView.placeholder = "Send a message..."
        
        messagesCollectionView.backgroundColor = UIColor(named: "backgroundColors")
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //messageInputBar.inputTextView.becomeFirstResponder()
        messagesCollectionView.reloadData()
        if let convoID = conversationID {
            listenForMessages(id: convoID, shouldScrollToBottom: true)
        }
    }
    
    @objc func didTapInfoButton() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "userDetailsVC") as? UserDetailsViewController else {
                return
            }
            viewController.projectCreatorEmail = self.otherUserEmail
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func removeNewConversationsVC() {
        guard let count = navigationController?.viewControllers.count else {
            return
        }
        navigationController?.viewControllers.remove(at: count - 2)
    }
    
    // MARK: - Adding Rich Messages
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = UIColor(named: "purpleColor")
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Location Picker
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print("Latitude = \(latitude), longitude = \(longitude)")
            
            guard let messageID = strongSelf.createMessageID(), let conversationID = strongSelf.conversationID, let name = strongSelf.title, let selfSender = strongSelf.selfSender else {
                return
            }
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationID, recepientEmail: strongSelf.otherUserEmail, recepientFcmToken: strongSelf.otherUserFcmToken!, recepientName: name, NewMessage: message, completion: { success in
                if success {
                    print("Location message sent!")
                } else {
                    print("Failed to send location message")
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    // MARK: - Video Picker
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach video", message: "What would you like to attach a video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Record video...", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose video...", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Photo Picker
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach photo", message: "What would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Take photo...", style: .default, handler: { [weak self] _ in
            // Make sure permissions are granted
            
            
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose photo...", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Listening for Messages
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        // Download list of current messages
        DatabaseManager.shared.getAllMessagesForConversation(with: id, currentMessages: messages, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("Current messages array is empty")
                    return
                }
                self?.messages = messages
                self?.messages.sort()
                self?.messagesCollectionView.reloadData()
                
                if shouldScrollToBottom {
                    DispatchQueue.main.async {
                        self?.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        })
        
        // Listen for new messages
        DatabaseManager.shared.listenForNewMessages(with: id, currentMessages: messages, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("New messages array is empty")
                    return
                }
                self?.messages = messages
                self?.messages.sort()
                self?.messagesCollectionView.reloadData()
                
                // Re-load any photo messages back into the bubbles
                
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        })
    }
    
    private func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else {
            return
        }
        
        messages.append(message)
        messages.sort()
        
        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
}

// MARK: - Image Picker
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageID = createMessageID(), let conversationID = conversationID, let selfSender = selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            // Uploading image
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    print("Uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus"), let name = self?.title else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo(media))
                    
                    // Send message
                    DatabaseManager.shared.sendMessage(to: conversationID, recepientEmail: strongSelf.otherUserEmail, recepientFcmToken: strongSelf.otherUserFcmToken!, recepientName: name, NewMessage: message, completion: { success in
                        if success {
                            print("Photo message sent!")
                            self?.messagesCollectionView.reloadData()
                        } else {
                            print("Failed to send photo message")
                        }
                    })
                case .failure(let error):
                    print("Message photo upload error: \(error)")
                }
            })
        } else if let videoURL = info[.mediaURL] as? URL {
            // Uploading video
            let fileName = "video_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: videoURL, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    print("Uploaded message video: \(urlString)")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus"), let name = self?.title else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .video(media))
                    
                    // Send message
                    DatabaseManager.shared.sendMessage(to: conversationID, recepientEmail: strongSelf.otherUserEmail, recepientFcmToken: strongSelf.otherUserFcmToken!, recepientName: name, NewMessage: message, completion: { success in
                        if success {
                            print("Video message sent!")
                            self?.messagesCollectionView.reloadData()
                        } else {
                            print("Failed to send photo message")
                        }
                    })
                case .failure(let error):
                    print("Message photo upload error: \(error)")
                }
            })
        }
    }
}

// MARK: - Sending Messages
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageID = createMessageID() else {
            return
        }
        
        let blockedWords = BlockedWords.shared.blockedWords()
        var messageIsAcceptable = true
        
        // Check the strings for bad words in the array
        var messageContains = false
        
        let messageArray = text.components(separatedBy: " ")
        for badWord in blockedWords {
            for word in messageArray {
                if word.lowercased() == badWord {
                    messageContains = true
                    messageIsAcceptable = false
                }
            }
        }
        
        if messageContains {
            alertManager.showAlert(title: "Inappropriate language", message: "There are some less-than-ideal words in your message. Please make it more appropriate.")
            return
        }
        
        if messageIsAcceptable {
            inputBar.inputTextView.text = ""
            
            print("Sending \(text)")
            
            // Send message
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
            if isNewConversation {
                // create new convo in database
                DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", otherUserFcmToken: otherUserFcmToken!, firstMessage: message, completion: { [weak self] success in
                    if success {
                        print("Message sent!")
                        self?.isNewConversation = false
                        let newConversationID = "conversation_\(message.messageId)"
                        self?.conversationID = newConversationID
                        self?.listenForMessages(id: newConversationID, shouldScrollToBottom: true)
                        
                        self?.removeNewConversationsVC()
                    } else {
                        print("Failed to send")
                    }
                })
            } else {
                // append to existing convo data
                guard let conversationID = conversationID, let name = self.title else {
                    return
                }
                
                DatabaseManager.shared.sendMessage(to: conversationID, recepientEmail: otherUserEmail, recepientFcmToken: otherUserFcmToken!, recepientName: name, NewMessage: message, completion: { [weak self] success in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if success {
                        print("Message sent!")
                        strongSelf.insertNewMessage(message)
                        strongSelf.messagesCollectionView.scrollToBottom(animated: true)
                    } else {
                        print("Failed to send")
                    }
                })
            }
        }
    }
    
    private func createMessageID() -> String? {
        let dateString = FormatDate.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            return nil
        }
        
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print("Created message ID: \(newIdentifier)")
        return newIdentifier
    }
}

// MARK: - Collection View Delegates
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cashed")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
        
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        avatarView.setCorner(radius: 10)
        
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            if let currentUserImageURL = self.senderPhotoURL {
                // URL is saved
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else {
                // fetch URL
                let email = UserDefaults.standard.string(forKey: "email")
                let storageRef = Storage.storage().reference().child("profile images").child("\(email!) - profile image.png")
                storageRef.downloadURL(completion: { [weak self] (url, error) in
                    if error != nil {
                        self?.alertManager.showAlert(title: "Error downloading profile image", message: "There was a problem downloading your profile image. \n \n Error: \(error!)")
                    }
                    self?.senderPhotoURL = url
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: url, completed: nil)
                    }
                })
            }
        } else {
            if let otherUserImageURL = self.otherUserPhotoURL {
                // URL is saved
                avatarView.sd_setImage(with: otherUserImageURL, completed: nil)
            } else {
                // fetch URL
                let storageRef = Storage.storage().reference().child("profile images").child("\(otherUserEmail) - profile image.png")
                storageRef.downloadURL(completion: { [weak self] (url, error) in
                    if error != nil {
                        self?.alertManager.showAlert(title: "Error downloading profile image", message: "There was a problem downloading the other user's profile image. \n \n Error: \(error!)")
                    }
                    self?.otherUserPhotoURL = url
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: url, completed: nil)
                    }
                })
            }
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(named: "purpleColor")!: .secondarySystemFill
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            DispatchQueue.main.async {
                imageView.sd_setImage(with: imageURL, completed: nil)
            }
        default:
            break
        }
    }
}

// MARK: - Message Interactions
extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
