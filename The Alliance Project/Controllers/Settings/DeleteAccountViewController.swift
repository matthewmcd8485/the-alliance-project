//
//  DeleteAccountViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/14/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import AuthenticationServices
import FirebaseUI
import FirebaseStorage
import FirebaseFirestore
import GoogleSignIn

class DeleteAccountViewController: UIViewController, FUIAuthDelegate {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var buttonView: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "DELETE ACCOUNT"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        buttonView.layer.cornerRadius = 10
    }
    
    // MARK: - Reauthenticate
    @IBAction func signInButton(_ sender: Any) {
        if let authUI = FUIAuth.defaultAuthUI() {
            authUI.providers = [FUIOAuth.appleAuthProvider(), FUIGoogleAuth(), FUIEmailAuth()]
            FUIOAuth.swizzleAppleAuthCompletion()
            authUI.delegate = self
            
            let authViewController = authUI.authViewController()
            present(authViewController, animated: true)
        }
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if error != nil {
            AlertManager.shared.showAlert(title: "Error authenticating account", message: "There was an error authenticating the account. Please try again. \n \n Error: \(error!)")
        } else if let user = authDataResult?.user {
            
            print("Logged in! uid: \(user.uid)")
            
            let email = UserDefaults.standard.string(forKey: "email")
            
            // Deleting Project Subcollection
            db.collection("users").document("\(email!)").collection("projects").getDocuments() { [weak self] (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var count = 0
                    for document in querySnapshot!.documents {
                        count += 1
                        let data = document.data()
                        let title = data["Project Title"] as? String ?? ""
                        self?.db.collection("users").document("\(email!)").collection("projects").document("\(title)").delete() { err in
                            if err != nil {
                                print("Error removing project '\(title)': \(err!)")
                            } else {
                                print("Project '\(title)' successfully removed!")
                            }
                        }
                    }
                }
            }
            
            // MARK: - Delete User
            // Deleting profile image from Firebase Storage
            let storage = Storage.storage().reference()
            storage.child("profile images").child("\(email!) - profile image.png").delete { error in
                if let error = error {
                    print("Error deleting profile image from Firebase Storage: \(error)")
                } else {
                    print("Profile image successfully deleted!")
                }
            }
            
            // Deleting User
            db.collection("users").document("\(email!)").delete() { err in
                if err != nil {
                    print("Error removing document: \(err!)")
                } else {
                    print("Document successfully removed!")
                    
                    UserDefaults.standard.set("", forKey: "instagram")
                    UserDefaults.standard.set("", forKey: "twitter")
                    UserDefaults.standard.set("", forKey: "youtube")
                    UserDefaults.standard.set("", forKey: "website")
                    UserDefaults.standard.set("", forKey: "userIdentifier")
                    UserDefaults.standard.set("", forKey: "email")
                    UserDefaults.standard.set("", forKey: "fullName")
                    UserDefaults.standard.set([""], forKey: "blockedUsers")
                }
            }
            
            // Deleting Firebase Auth user
            let user = Auth.auth().currentUser
            user?.delete { error in
                if let error = error {
                    print("Error deleting user authentication profile: \(error)")
                } else {
                    print("Authentication account deleted!")
                }
            }
            
            Messaging.messaging().unsubscribe(fromTopic: "All users") { error in
                guard error == nil else {
                    print("Error unsubscribing from notifications: \(error!)")
                    return
                }
                print("Unsubscribed from notification topic: All users")
            }
            
            UserDefaults.standard.set("", forKey: "authCredential")
            UserDefaults.standard.setValue(false, forKey: "loggedIn")
            
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
