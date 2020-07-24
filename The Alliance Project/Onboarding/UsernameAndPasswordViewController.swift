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
    
    let locationManager = LocationManager()
    
    var user: User?
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameField.delegate = self
        self.passwordField.delegate = self
        
        setCurrentLocation()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    var usernameAlreadyExists: Bool = false
    
    var location: String = ""
    private func setCurrentLocation() {
        guard let exposedLocation = self.locationManager.exposedLocation else {
            print("*** Error in \(#function): exposedLocation is nil")
            return
        }
        
        self.locationManager.getPlace(for: exposedLocation) { placemark in
            guard let placemark = placemark else { return }
            
            if let town = placemark.locality {
                self.location += "\(town)"
            }
            if let state = placemark.administrativeArea {
                self.location += ", \(state)"
            }
        }
    }
    
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
                
                let fullName = user!.firstName + " " + user!.lastName
                
                if location == "" {
                    location = "Location not set"
                }
                
                UserDefaults.standard.set(usernameField.text!, forKey: "username")
                UserDefaults.standard.set(location, forKey: "cityAndState")
                UserDefaults.standard.set(fullName, forKey: "fullName")
                UserDefaults.standard.set(self.user!.email, forKey: "email")
                
                
                db.collection("users").document("\(usernameField.text!)").setData([
                    
                    "Full Name": fullName,
                    "Email Address": self.user!.email,
                    "Username": usernameField.text!,
                    "Password": passwordField.text!,
                    "Instagram": "",
                    "Twitter": "",
                    "YouTube": "",
                    "Website": "",
                    "Locality": location,
                    "Apple ID User Identifier": self.user!.id,
                    "Profile Image URL": "No profile picture yet"
                    
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
