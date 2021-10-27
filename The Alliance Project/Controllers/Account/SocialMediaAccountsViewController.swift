//
//  SocialMediaAccountsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/17/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class SocialMediaAccountsViewController: UIViewController {

    let db = Firestore.firestore()
    let email = UserDefaults.standard.string(forKey: "email")
    
    @IBOutlet weak var instagramHandleLabel: UILabel!
    @IBOutlet weak var youTubeLabel: UILabel!
    @IBOutlet weak var twitterHandleLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Link Social Accounts"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        updateAccounts()

    }
    
    // MARK: - Updating Accounts
    func updateAccounts() {
        if let instagram = UserDefaults.standard.string(forKey: "instagram") {
            if UserDefaults.standard.string(forKey: "instagram") != "" {
                instagramHandleLabel.text = "Account linked as @\(instagram)"
            }
        }
        if let youtube = UserDefaults.standard.string(forKey: "youtube") {
            if UserDefaults.standard.string(forKey: "youtube") != "" {
                youTubeLabel.text = "Channel linked as \(youtube)"
            }
        }
        if let twitter = UserDefaults.standard.string(forKey: "twitter") {
            if UserDefaults.standard.string(forKey: "twitter") != "" {
                twitterHandleLabel.text = "Account linked as @\(twitter)"
            }
        }
        if let website = UserDefaults.standard.string(forKey: "website") {
            if UserDefaults.standard.string(forKey: "website") != "" {
                websiteLabel.text = "Website linked as \(website)"
            }
        }
    }
    
    var handleString: String = ""
    
    // MARK: - Link Instagram
    @IBAction func linkInstagram(_ sender: Any) {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Link Your Instagram", message: "Link your Instagram account to help others verify your skills. Do not enter the @ symbol.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
                (action) -> Void in

                if let handle = textField?.text {
                    if handle != "" {
                        print("Handle = \(handle)")
                        self.instagramHandleLabel.text = "Account linked as @\(handle)"
                        UserDefaults.standard.set(handle, forKey: "instagram")
                        self.db.collection("users").document("\(self.email!)").setData(["Instagram": "\(handle)"], merge: true)
                    }
                } else {
                    print("No Username entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Instagram"
        }
        
        alertController.addAction(UIAlertAction(title: "Unlink", style: .destructive, handler: {action in
            self.db.collection("users").document("\(self.email!)").setData(["Instagram" : ""], merge: true)
            UserDefaults.standard.set("", forKey: "instagram")
            self.instagramHandleLabel.text = "Account not linked"
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Link Twitter
    @IBAction func linkTwitter(_ sender: Any) {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Link Your Twitter", message: "Link your Twitter to help others verify your skills. Do not enter the @ symbol.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
                (action) -> Void in

                if let handle = textField?.text {
                    if handle != "" {
                        print("Handle = \(handle)")
                        self.twitterHandleLabel.text = "Account linked as @\(handle)"
                        UserDefaults.standard.set(handle, forKey: "twitter")
                        self.db.collection("users").document("\(self.email!)").setData(["Twitter": "\(handle)"], merge: true)
                    }
                } else {
                    print("No Username entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Twitter"
        }
        
        alertController.addAction(UIAlertAction(title: "Unlink", style: .destructive, handler: {action in
            self.db.collection("users").document("\(self.email!)").setData(["Twitter" : ""], merge: true)
            UserDefaults.standard.set("", forKey: "twitter")
            self.twitterHandleLabel.text = "Account not linked"
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Link YouTube
    @IBAction func linkYouTube(_ sender: Any) {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Link Your YouTube Channel", message: "Link your YouTube Channel URL by visiting your channel page online and copying the website URL.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
            (action) -> Void in
            
            if let handle = textField?.text {
                if handle != "" {
                    print("Channel = \(handle)")
                    self.youTubeLabel.text = "Channel linked!"
                    UserDefaults.standard.set(handle, forKey: "youtube")
                    self.db.collection("users").document("\(self.email!)").setData(["YouTube": "\(handle)"], merge: true)
                }
            } else {
                print("No channel entered")
            }
        }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your YouTube Channel URL"
        }
        
        alertController.addAction(UIAlertAction(title: "Unlink", style: .destructive, handler: {action in
            self.db.collection("users").document("\(self.email!)").setData(["YouTube" : ""], merge: true)
            UserDefaults.standard.set("", forKey: "youtube")
            self.youTubeLabel.text = "Channel not linked"
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Link Website
    @IBAction func linkWebsite(_ sender: Any) {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Link Your Website", message: "Link your website to help others verify your skills.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
                (action) -> Void in

                if let handle = textField?.text {
                    if handle != "" {
                        print("Website = \(handle)")
                        self.websiteLabel.text = "Website linked as \(handle)"
                        UserDefaults.standard.set(handle, forKey: "website")
                        self.db.collection("users").document("\(self.email!)").setData(["Website": "\(handle)"], merge: true)
                    }
                } else {
                    print("No website entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Website"
        }
        
        alertController.addAction(UIAlertAction(title: "Unlink", style: .destructive, handler: {action in
            self.db.collection("users").document("\(self.email!)").setData(["Website" : ""], merge: true)
            UserDefaults.standard.set("", forKey: "website")
            self.websiteLabel.text = "Website not linked"
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
