//
//  LinkAccountsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/28/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import AuthenticationServices

class LinkAccountsViewController: UIViewController, UITextFieldDelegate {

    var user: User?
    var id: String?
    
    let db = Firestore.firestore()
    let profileImage = UIImageView()
    
    @IBOutlet weak var emailTextField: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        id = user?.id
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    var fullName: String = ""
    var cityAndState: String = ""
    @IBAction func linkButton(_ sender: Any) {
        if emailTextField.text == "" {
            let alert = UIAlertController(title: "Email field is empty", message: "Please enter your email before continuing.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            db.collection("users").whereField("Email Address", isEqualTo: emailTextField.text!).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    if querySnapshot!.documents.count == 0 {
                        let alert = UIAlertController(title: "Something's not right", message: "There seems to be an issue with the email you entered. Please try again.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        for document in querySnapshot!.documents {
                            print("\(document.documentID) => \(document.data())")
                            let username = document.get("Username")
                            self.db.collection("users").document("\(username!)").setData(["Apple ID User Identifier": "\(self.id!)"], merge: true)
                            self.fullName = document.get("Full Name") as! String
                            self.cityAndState = document.get("Locality") as! String
                            
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
                            
                            UserDefaults.standard.set(self.fullName, forKey: "fullName")
                            UserDefaults.standard.set(true, forKey: "loggedIn")
                            UserDefaults.standard.set(username, forKey: "username")
                            UserDefaults.standard.set(self.cityAndState, forKey: "cityAndState")
                            UserDefaults.standard.set(self.emailTextField.text!, forKey: "email")
                            
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
