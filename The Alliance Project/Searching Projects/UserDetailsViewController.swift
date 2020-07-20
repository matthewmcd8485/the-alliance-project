//
//  UserDetailsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/17/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class UserDetailsViewController: UIViewController {

    let db = Firestore.firestore()
    
    var projectCreatorEmail: String?
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var localityLabel: UILabel!
    @IBOutlet weak var tapBelowLabel: UILabel!
    
    @IBOutlet weak var instagramLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var twitterLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    
    var instagramAccount: String = ""
    var twitterAccount: String = ""
    var youtubeChannel: String = ""
    var websiteLink: String = ""
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameLabel.text = UserDefaults.standard.string(forKey: "selectedProjectUsername")
        
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        
        loadUserImage()
        loadUserData()
    }

    func loadUserImage() {
        db.collection("users").whereField("Email Address", isEqualTo: projectCreatorEmail!).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting user documents: \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    let alert = UIAlertController(title: "Creator image not found", message: "The creator's profile image could not be found. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        let username = document.get("Username")
                        let profileImageURL: String = document.get("Profile Image URL") as! String
                        print(profileImageURL)
                        
                        // download picture from storage
                        // save picture to device
                        if profileImageURL != "No profile picture yet" {
                            let storageRef = Storage.storage().reference(withPath: "profile images/\(username!) - profile image.png")
                            storageRef.getData(maxSize: 2 * 2048 * 2048) { data, error in
                                if let error = error {
                                    print(error)
                                } else {
                                    // Data for profile image is returned
                                    print("data = \(data!)")
                                    let placeholderImage = UIImage(named: "Onboarding1.jpg")
                                    self.profileImageView.sd_setImage(with: storageRef, placeholderImage: placeholderImage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadUserData() {
        db.collection("users").whereField("Email Address", isEqualTo: projectCreatorEmail!).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting project documents: \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    let alert = UIAlertController(title: "Project not found", message: "The project selected could not be found. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")

                        self.localityLabel.text = document.get("Locality") as? String
                        self.tapBelowLabel.text = "Tap below to visit \(document.get("Full Name")!)'s social media accounts"
                        
                        if document.get("Instagram") as? String != "" {
                            let instagram = document.get("Instagram") as? String
                            self.instagramAccount = instagram!
                            self.instagramLabel.text = "@\(instagram!)"
                        }
                        if document.get("YouTube") as? String != "" {
                            let youtube = document.get("YouTube") as? String
                            self.youtubeChannel = youtube!
                            self.channelLabel.text = "\(youtube!)"
                        }
                        if document.get("Twitter") as? String != "" {
                            let twitter = document.get("Twitter") as? String
                            self.twitterAccount = twitter!
                            self.twitterLabel.text = "@\(twitter!)"
                        }
                        if document.get("Website") as? String != "" {
                            let website = document.get("Website") as? String
                            self.websiteLink = website!
                            self.websiteLabel.text = "\(website!)"
                        }

                    }
                }
            }
        }
    }
    
    @IBAction func instagramButton(_ sender: Any) {
        if instagramLabel.text != "Account not linked" {
            let appURL = URL(string: "instagram://user?username=\(instagramAccount)")!
            let application = UIApplication.shared

            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                let webURL = URL(string: "https://instagram.com/\(instagramAccount)")!
                application.open(webURL)
            }
        }
    }
    
    @IBAction func youtubeButton(_ sender: Any) {
        let alert = UIAlertController(title: "Hold Tight!", message: "I need to figure out how to link to people's YouTube accounts. It fails when there is a space in the channel name. Check back in the next build for a fix!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func twitterButton(_ sender: Any) {
        if twitterLabel.text != "Account not linked" {
            let appURL = URL(string: "twitter://user?screen_name=\(twitterAccount)")!
            let application = UIApplication.shared
            
            if application.canOpenURL(appURL) {
                application.open(appURL)
            }
            else {
                let webURL = URL(string: "https://twitter.com/\(twitterAccount)")!
                application.open(webURL)
            }
        }
    }
    
    @IBAction func websiteButton(_ sender: Any) {
        if websiteLabel.text != "Website not linked" {
            let application = UIApplication.shared
            let webURL = URL(string: "https://\(websiteLink)")!
            application.open(webURL)
        }
    }
    
}
