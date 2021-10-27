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
    let alertManager = AlertManager.shared
    
    public var projectCreatorEmail: String?
    
    @IBOutlet weak var localityLabel: UILabel!
    @IBOutlet weak var tapBelowLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var instagramLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var twitterLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var unsplashButton: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundDimView: UIView!
    
    var instagramAccount: String = ""
    var twitterAccount: String = ""
    var youtubeChannel: String = ""
    var websiteLink: String = ""
    var name: String = ""
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "User Details"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "hand.raised.slash"), for: .normal)
        button.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.alpha = 0
        
        backgroundImageView.alpha = 0
        backgroundDimView.alpha = 0
        
        unsplashButton.alpha = 0
        
        loadUserImage()
        loadUserData()
    }
    
    // MARK: - User Actions / Reporting
    @objc private func didTapInfoButton() {
        let currentEmail = UserDefaults.standard.string(forKey: "email")
        if currentEmail == projectCreatorEmail {
            alertManager.showAlert(title: "Hold up!", message: "You can't report or block yourself. Nice try, though!")
        } else {
            let alert = UIAlertController(title: "User Actions", message: "You can report or block a user here.", preferredStyle: .actionSheet)
            
            // Report as inappropriate
            alert.addAction(UIAlertAction(title: "Report user as inappropriate", style: .default, handler: { [weak self] action in
                guard let strongSelf = self else {
                    return
                }
                
                // Add user to collection of reportees
                let date = FormatDate.dateFormatter.string(from: Date())
                ReportingManager.shared.reportUser(with: strongSelf.projectCreatorEmail!, name: (self?.name)!, date: date, kind: "Inappropriate", completion: { success in
                    if success {
                        strongSelf.alertManager.showAlert(title: "Thank you", message: "Your report has been received. Thank you for helping us maintain a safe and inclusive community on The Alliance Project.")
                    }
                })
            }))
            
            // Report as spam
            alert.addAction(UIAlertAction(title: "Report user as spam", style: .default, handler: { [weak self] action in
                guard let strongSelf = self else {
                    return
                }
                
                // Add user to collection of reportees
                let date = FormatDate.dateFormatter.string(from: Date())
                ReportingManager.shared.reportUser(with: strongSelf.projectCreatorEmail!, name: (self?.name)!, date: date, kind: "Spam", completion: { success in
                    if success {
                        strongSelf.alertManager.showAlert(title: "Thank you", message: "Your report has been received. Thank you for helping us maintain a safe and inclusive community on The Alliance Project.")
                    }
                })
            }))
            
            // Block user
            alert.addAction(UIAlertAction(title: "Block user", style: .destructive, handler: { action in
                let secondAlert = UIAlertController(title: "Are you sure?", message: "This action cannot be undone.", preferredStyle: .actionSheet)
                secondAlert.addAction(UIAlertAction(title: "Block user", style: .destructive, handler: { [weak self] action in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    DatabaseManager.shared.blockUser(with: strongSelf.projectCreatorEmail!, completion: { success in
                        if success {
                            let alert = UIAlertController(title: "User blocked", message: "You have successfully blocked this user.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                                strongSelf.navigationController?.popToRootViewController(animated: true)
                            }))
                            strongSelf.present(alert, animated: true, completion: nil)
                        } else {
                            strongSelf.alertManager.showAlert(title: "Error blocking user", message: "There was an error when blocking the user. Please try again.")
                        }
                    })
                }))
                secondAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(secondAlert, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Load User Image
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
                        
                        let name = document.get("Full Name") as! String
                        self.name = name
                        self.nameLabel.text = "Hi, I'm \(name)"
                        
                        let email = document.get("Email Address") as! String
                        let backgroundImageURL = document.get("Profile Background Image URL") as? String ?? ""
                        let backgroundImageName = document.get("Profile Background Image Creator Name") as? String ?? "[Unknown User]"
                        let backgroundImageProfileURL = document.get("Profile Background Image Creator Profile Link") as? String ?? "https://www.unsplash.com"
                        
                        self.backgroundImageStrings = [backgroundImageURL, backgroundImageName, backgroundImageProfileURL]
                        
                        self.unsplashButton.setTitle("Image by \(backgroundImageName) on Unsplash", for: .normal)
                        self.configureBackgroundImage(with: backgroundImageURL)
                        
                        // Look for user's profile image
                        let storageRef = Storage.storage().reference().child("profile images").child("\(email) - profile image.png")
                        storageRef.downloadURL(completion: { [weak self] (url, error) in
                            if error != nil {
                                print("Failed to download user's profile url:", error!)
                                // Image does not exist
                                UIView.animate(withDuration: 0.5) {
                                    self?.profileImageView.alpha = 1
                                }
                                return
                            } else {
                                DispatchQueue.main.async {
                                    self?.profileImageView.sd_setImage(with: url!, completed: nil)
                                    UIView.animate(withDuration: 0.5) {
                                        self?.profileImageView.alpha = 1
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Load Background Image
    
    // [0] = Image URL, [1] = Creator Name, and [2] = Creator Profile URL
    var backgroundImageStrings: [String] = ["", "", ""]
    
    private func configureBackgroundImage(with urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        let token = "dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self?.backgroundImageView.image = image
                
                UIView.animate(withDuration: 0.5) {
                    self?.backgroundDimView.alpha = 1
                    self?.backgroundImageView.alpha = 1
                    self?.unsplashButton.alpha = 1
                    self?.unsplashButton.setTitleColor(UIColor(named: "lightPurpleColor"), for: .normal)
                    self?.instagramLabel.textColor = .white
                    self?.channelLabel.textColor = .white
                    self?.twitterLabel.textColor = .white
                    self?.websiteLabel.textColor = .white
                    self?.tapBelowLabel.textColor = .white
                    self?.nameLabel.textColor = .white
                    self?.localityLabel.textColor = .white
                }
                
            }
        }.resume()
    }
    
    @IBAction func unsplashButtonPressed(_ sender: Any) {
        guard unsplashButton.titleLabel?.text != "" else {
            return
        }
        
        if backgroundImageStrings[1] == "[Unknown User]" {
            let actionSheet = UIAlertController(title: "Visit the Unsplash Website", message: "There was an issue loading the background image creator's info, so we have to redirect you to Unsplash's home page instead. This will send you outside of The Alliance Project. Continue?", preferredStyle: .actionSheet)
            actionSheet.addAction((UIAlertAction(title: "Visit the Unsplash website", style: .default, handler: { action in
                if let path = URL(string: "https://www.unsplash.com?utm_source=The-Alliance-Project&utm_medium=referral") {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            })))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: "View \(backgroundImageStrings[1])'s Unsplash Profile", message: "This will send you outside of The Alliance Project. Continue?", preferredStyle: .actionSheet)
            actionSheet.addAction((UIAlertAction(title: "View \(backgroundImageStrings[1]) on Unsplash", style: .default, handler: { action in
                if let path = URL(string: "\(self.backgroundImageStrings[2])?utm_source=The-Alliance-Project&utm_medium=referral") {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            })))
            actionSheet.addAction(UIAlertAction(title: "Visit the Unsplash homepage", style: .default, handler: { action in
                if let path = URL(string: "https://unsplash.com?utm_source=The-Alliance-Project&utm_medium=referral") {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    // MARK: - Load User Data
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
                        
                        let location = document.get("Locality") as? String ?? "somewhere in the matrix"
                        self.localityLabel.text = "I'm from \(location)"
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
    
    // MARK: - Social Media Links
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
        if channelLabel.text != "Channel not linked" {
            let application = UIApplication.shared
            let webURL = URL(string: "\(youtubeChannel)")!
            application.open(webURL)
        }
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
