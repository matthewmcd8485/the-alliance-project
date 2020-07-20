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
    let username = UserDefaults.standard.string(forKey: "username")
    
    @IBOutlet weak var instagramHandleLabel: UILabel!
    @IBOutlet weak var youTubeLabel: UILabel!
    @IBOutlet weak var twitterHandleLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateAccounts()

    }
    
    // CHECK CLOUD FIRESTORE FOR THIS STUFF ON FIRST LAUNCH
    func updateAccounts() {
        if let instagram = UserDefaults.standard.string(forKey: "instagram") {
            instagramHandleLabel.text = "Account linked as @\(instagram)"
        }
        if let youtube = UserDefaults.standard.string(forKey: "youtube") {
            youTubeLabel.text = "Account linked as \(youtube)"
        }
        if let twitter = UserDefaults.standard.string(forKey: "twitter") {
            twitterHandleLabel.text = "Account linked as @\(twitter)"
        }
        if let website = UserDefaults.standard.string(forKey: "website") {
            websiteLabel.text = "Account linked as \(website)"
        }
    }
    
    var handleString: String = ""
    
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
                        self.db.collection("users").document("\(self.username!)").setData(["Instagram": "\(handle)"], merge: true)
                    }
                } else {
                    print("No Username entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Instagram"
        }
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
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
                        self.db.collection("users").document("\(self.username!)").setData(["Twitter": "\(handle)"], merge: true)
                    }
                } else {
                    print("No Username entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Twitter"
        }
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func linkYouTube(_ sender: Any) {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Link Your YouTube Channel", message: "Link your YouTube Channel to help others verify your skills.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
                (action) -> Void in

                if let handle = textField?.text {
                    if handle != "" {
                        print("Channel = \(handle)")
                        self.youTubeLabel.text = "Channel linked as \(handle)"
                        UserDefaults.standard.set(handle, forKey: "youtube")
                        self.db.collection("users").document("\(self.username!)").setData(["YouTube": "\(handle)"], merge: true)
                    }
                } else {
                    print("No channel entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your YouTube"
        }
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
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
                        self.db.collection("users").document("\(self.username!)").setData(["Website": "\(handle)"], merge: true)
                    }
                } else {
                    print("No website entered")
                }
            }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your Website"
        }
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
