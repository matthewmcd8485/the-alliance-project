//
//  UsernameAndPasswordViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/27/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation

class UsernameAndPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    let db = Firestore.firestore()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameField.delegate = self
        self.passwordField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    var usernameAlreadyExists: Bool = false
    
    @IBAction func finishButton(_ sender: Any) {
        if usernameField.text!.isEmpty || passwordField.text!.isEmpty {
            let alert = UIAlertController(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            
            db.collection("users").whereField("username", isEqualTo: usernameField.text!).getDocuments() {
                (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    if querySnapshot!.documents.count > 1 {
                        print(querySnapshot!.documents.count)
                        self.usernameAlreadyExists = true
                        let alert = UIAlertController(title: "Username already exists", message: "The username you entered already exists. Please choose a different username.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
            
            if usernameAlreadyExists == false {
                
                let fullName = UserDefaults.standard.string(forKey: "fullName")
                let age = UserDefaults.standard.integer(forKey: "age")
                let email = UserDefaults.standard.string(forKey: "email")
                
                UserDefaults.standard.set(usernameField.text!, forKey: "username")
                
                db.collection("users").document("\(fullName!)").setData([
                    
                    "full name": fullName!,
                    "age": age,
                    "email address": email!,
                    "username": usernameField.text!,
                    "password": passwordField.text!,
                    "twitter": "",
                    "instagram": "",
                    "youtube": "",
                    "website": ""
                    
                ]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        
                        let alert = UIAlertController(title: "Error creating account", message: "There was an error when creating the user account. Please try again.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        print("Document successfully written!")
                        
                        UserDefaults.standard.set(true, forKey: "loggedIn")
                        
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
    
    func checkForExistingUser()  {
        self.usernameAlreadyExists = false
        
        db.collection("users").whereField("username", isEqualTo: usernameField.text!).getDocuments() {
            (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if querySnapshot!.documents.count > 0 {
                }
            }
        }
    }
}
