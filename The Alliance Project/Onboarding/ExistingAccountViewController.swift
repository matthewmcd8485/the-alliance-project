//
//  ExistingAccountViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/27/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

class ExistingAccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    let db = Firestore.firestore()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.usernameField.delegate = self
        self.passwordField.delegate = self
        
        profileImage.clipsToBounds = true
        profileImage.layer.cornerRadius = 30
                
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
                view.addGestureRecognizer(tap)
    }
    
    var username: String = ""
    var password: String = ""
    var email: String = ""
    
    @IBAction func logInButton(_ sender: Any) {
       if usernameField.text!.isEmpty || passwordField.text!.isEmpty {
            let alert = UIAlertController(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            username = usernameField.text!
            password = passwordField.text!
        
            db.collection("users").whereField("Username", isEqualTo: username).whereField("Password", isEqualTo: password).getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if querySnapshot!.documents.count == 0 {
                            let alert = UIAlertController(title: "Invalid credentials", message: "The username or password entered was incorrect. Please try again.", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            for document in querySnapshot!.documents {
                                print("\(document.documentID) => \(document.data())")
                                
                                let username = document.get("Username")
                                let fullName = document.get("Full Name")
                                self.email = document.get("Email Address") as! String
                                let locality = document.get("Locality")
                                
                                let instagram = document.get("Instagram") as! String
                                let twitter = document.get("Twitter") as! String
                                let youtube = document.get("YouTube") as! String
                                let website = document.get("Website") as! String
                                UserDefaults.standard.set(instagram, forKey: "instagram")
                                UserDefaults.standard.set(twitter, forKey: "twitter")
                                UserDefaults.standard.set(youtube, forKey: "youtube")
                                UserDefaults.standard.set(website, forKey: "website")
                                
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
                                            let image = UIImage(data: data!)
                                            let placeholderImage = UIImage(named: "Onboarding1.jpg")
                                            self.profileImage.sd_setImage(with: storageRef, placeholderImage: placeholderImage)
                                            self.store(image: image!, forKey: "profileImage", withStorageType: .fileSystem)
                                        }
                                    }
                                }

                                UserDefaults.standard.set(fullName, forKey: "fullName")
                                UserDefaults.standard.set(true, forKey: "loggedIn")
                                UserDefaults.standard.set(self.username, forKey: "username")
                                UserDefaults.standard.set(self.email, forKey: "email")
                                UserDefaults.standard.set(locality, forKey: "cityAndState")
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "homeScreen")
                            vc.modalPresentationStyle = .fullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    enum StorageType {
        case userDefaults
        case fileSystem
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    private func store(image: UIImage, forKey key: String, withStorageType storageType: StorageType) {
        if let pngRepresentation = image.pngData() {
            switch storageType {
            case .fileSystem:
                if let filePath = filePath(forKey: key) {
                    do  {
                        try pngRepresentation.write(to: filePath,
                                                    options: .atomic)
                    } catch let err {
                        print("Saving file resulted in error: ", err)
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation, forKey: key)
            }
        }
    }
    
    private func retrieveImage(forKey key: String, inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
                let fileData = FileManager.default.contents(atPath: filePath.path),
                let image = UIImage(data: fileData) {
                return image
            }
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
}
