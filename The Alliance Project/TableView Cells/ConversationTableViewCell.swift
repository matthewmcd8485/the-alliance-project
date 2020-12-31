//
//  ConversationTableViewCell.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/15/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseStorage

class ConversationTableViewCell: UITableViewCell {

    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AcherusGrotesque-Bold", size: 22)
        label.textColor = UIColor(named: "purpleColor")
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AcherusGrotesque-Regular", size: 14)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 75, height: 75)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 0, width: contentView.width - 20 - userImageView.width, height: contentView.height/2)
        userMessageLabel.frame = CGRect(x: userImageView.right + 10, y: (userNameLabel.bottom + 30)/2, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20)/2)
        
    }
    
    public func configure(with model: Conversation) {
        switch model.latestMessage.kind {
        case .location:
            userMessageLabel.text = "Attachment: 1 Location"
        case .photo:
            userMessageLabel.text = "Attachment: 1 Photo"
        case .video:
            userMessageLabel.text = "Attachment: 1 Video"
        case .text:
            userMessageLabel.text = model.latestMessage.text
        }
        userNameLabel.text = model.name
        
        let email = model.otherUserEmail
        let storageRef = Storage.storage().reference().child("profile images").child("\(email) - profile image.png")
        storageRef.downloadURL(completion: { [weak self] (url, error) in
            if error != nil {
                print("Failed to download url:", error!)
                return
            } else {
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url!, completed: nil)
                }
            }
        })
    }
}
