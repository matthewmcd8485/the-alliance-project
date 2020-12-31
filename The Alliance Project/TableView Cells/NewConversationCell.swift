//
//  NewConversationCell.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/22/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import SDWebImage
import Firebase
import FirebaseStorage

class NewConversationTableViewCell: UITableViewCell {

    static let identifier = "NewConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: 50)
        
    }
    
    public func configure(with model: [String: String]) {
        userNameLabel.text = model["name"]
        guard let email = model["email"] else {
            return
        }
        
        // Look for user's profile image
        let storageRef = Storage.storage().reference().child("profile images").child("\(email) - profile image.png")
        storageRef.downloadURL(completion: { [weak self] (url, error) in
            if error != nil {
                print("Failed to download user's profile url:", error!)
                // Image does not exist, download placeholder instead
                let placeholderStorageRef = Storage.storage().reference().child("profile images").child("placeholder.png")
                placeholderStorageRef.downloadURL(completion: { [weak self] (url, error) in
                    if error != nil {
                        print("Failed to download user's profile url:", error!)
                        return
                    } else {
                        DispatchQueue.main.async {
                            self?.userImageView.sd_setImage(with: url!, completed: nil)
                        }
                    }
                })
                return
            } else {
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url!, completed: nil)
                }
            }
        })
    }
}
