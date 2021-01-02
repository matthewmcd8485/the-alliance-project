//
//  SettingsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 8/1/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import FirebaseFirestore
import FirebaseUI

class SettingsViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    let authUI = FUIAuth.defaultAuthUI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SETTINGS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        deleteDataButton.titleLabel?.numberOfLines = 2
        deleteDataButton.titleLabel?.lineBreakMode = .byWordWrapping
    }
    
    @IBOutlet weak var deleteDataButton: UIButton!
    
    @IBAction func viewSettings(_ sender: Any) {
        UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func privacyPolicy(_ sender: Any) {
        guard let url = URL(string: "https://matthewdevteam.weebly.com/privacy.html") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func termsOfService(_ sender: Any) {
        guard let url = URL(string: "https://matthewdevteam.weebly.com/terms-and-conditions.html") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Log Out
    @IBAction func logOutButton(_ sender: Any) {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure that you want to log out?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] action in
            
            // Remove profile image from memory here!
            
            do {
                try self?.authUI?.signOut()
            } catch {
                print("Sign out process failed")
            }
            
            Messaging.messaging().unsubscribe(fromTopic: "All users") { error in
                print("Unsubscribed from notification topic: All users")
            }
            
            UserDefaults.standard.set(false, forKey: "loggedIn")
            UserDefaults.standard.set(false, forKey: "locationErrorDismissal")
            UserDefaults.standard.set("", forKey: "authCredential")
            UserDefaults.standard.set([""], forKey: "blockedUsers")
            UserDefaults.standard.set("", forKey: "instagram")
            UserDefaults.standard.set("", forKey: "twitter")
            UserDefaults.standard.set("", forKey: "youtube")
            UserDefaults.standard.set("", forKey: "website")
            
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Delete User Data
    @IBAction func deleteUserDataButton(_ sender: Any) {
        let alert = UIAlertController(title: "Delete User Data", message: "Deleting user data will completely destroy your user account. Are you sure that you want to do this?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out Normally", style: .default, handler: { [weak self] action in
            UserDefaults.standard.set(false, forKey: "loggedIn")
            UserDefaults.standard.set(false, forKey: "locationErrorDismissal")
            UserDefaults.standard.set("", forKey: "userIdentifier")
            UserDefaults.standard.set("", forKey: "instagram")
            UserDefaults.standard.set("", forKey: "twitter")
            UserDefaults.standard.set("", forKey: "youtube")
            UserDefaults.standard.set("", forKey: "website")
            UserDefaults.standard.set("", forKey: "authCredential")
            UserDefaults.standard.set([""], forKey: "blockedUsers")
            
            do {
                try self?.authUI?.signOut()
            } catch {
                print("Sign out process failed")
            }
            
            Messaging.messaging().unsubscribe(fromTopic: "All users") { error in
                print("Unsubscribed from notification topic: All users")
            }
            
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Log Out & Delete User Data", style: .destructive, handler: { [weak self] action in
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "deleteAccountVC") as? DeleteAccountViewController
                else { return }
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

