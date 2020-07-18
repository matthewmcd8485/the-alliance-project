//
//  ThirdOnboardingViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/11/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import AuthenticationServices

class ThirdOnboardingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var createTitle: UILabel!
    
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    
    let db = Firestore.firestore()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        self.firstNameField.delegate = self
        self.lastNameField.delegate = self
        self.emailField.delegate = self
        
        //let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        //view.addGestureRecognizer(tap)

    }
    
    func setupView() {
        let appleButton = ASAuthorizationAppleIDButton()
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.addTarget(self, action: #selector(didTapAppleButton), for: .touchUpInside)
        
        view.addSubview(appleButton)
        NSLayoutConstraint.activate([
            appleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 75),
            appleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            appleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    @objc
    func didTapAppleButton() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    var firstName: String = ""
    var lastName: String = ""
    var fullName: String = ""
    var email: String = ""
    
    @IBAction func nextButton(_ sender: Any) {
        if firstNameField.text!.isEmpty || lastNameField.text!.isEmpty || emailField.text!.isEmpty {
            
            let alert = UIAlertController(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            
            firstName = firstNameField.text!
            lastName = lastNameField.text!
            fullName = firstName + " " + lastName
            email = emailField.text!
            
            let user = User(firstName: firstName, lastName: lastName, email: email, id: "Apple ID Not Used")
            self.performSegue(withIdentifier: "finishAppleSetupSegue", sender: user)
            
        }
    }
    
    func createSpinnerView() {
        let child = SpinnerViewController()
        
        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    var username: String = ""
    var profileImage = UIImageView()
    var cityAndState: String = ""
    func downloadUserProfileAndFinishSetup(user: User) {
        
        //let email = user.email
        let id = user.id
        
        db.collection("users").whereField("Apple ID User Identifier", isEqualTo: id).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    if querySnapshot!.documents.count == 0 {
                        self.performSegue(withIdentifier: "linkAccountsSegue", sender: user)
                    } else {
                        for document in querySnapshot!.documents {
                            print("\(document.documentID) => \(document.data())")
                            
                            let fullName = document.get("Full Name")
                            self.username = document.get("Username") as! String
                            self.cityAndState = document.get("Locality") as! String
                            self.email = document.get("Email Address") as! String
                            let profileImageURL: String = document.get("Profile Image URL") as! String
                            print(profileImageURL)
                            
                            // download picture from storage
                            // save picture to device
                            if profileImageURL != "No profile picture yet" {
                                let storageRef = Storage.storage().reference(withPath: "profile images/\(self.username) - profile image.png")
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
                            UserDefaults.standard.set(self.cityAndState, forKey: "cityAndState")
                            UserDefaults.standard.set(self.email, forKey: "email")
                            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let usernameAndPasswordVC = segue.destination as? UsernameAndPasswordViewController, let user = sender as? User {
            usernameAndPasswordVC.user = user
        }
        if let linkAccountsVC = segue.destination as? LinkAccountsViewController, let user = sender as? User {
            linkAccountsVC.user = user
        }
    }
}

extension ThirdOnboardingViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            createSpinnerView()
            let user = User(credentials: credentials)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                if user.firstName == "" {
                    self.downloadUserProfileAndFinishSetup(user: user)
                } else {
                    self.performSegue(withIdentifier: "finishAppleSetupSegue", sender: user)
                }
            })

            
            
        default:
            break
            
            // auto login
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        print("error with authorization:", error)
    }
}

extension ThirdOnboardingViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return view.window!
    }
}
