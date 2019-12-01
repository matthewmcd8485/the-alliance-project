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
    @IBOutlet var ageField: UITextField!
    @IBOutlet var emailField: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.firstNameField.delegate = self
        self.lastNameField.delegate = self
        self.ageField.delegate = self
        self.emailField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
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
    var age: Int = 0
    var email: String = ""
    
    @IBAction func nextButton(_ sender: Any) {
        if firstNameField.text!.isEmpty || lastNameField.text!.isEmpty || ageField.text!.isEmpty || emailField.text!.isEmpty {
            
            let alert = UIAlertController(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        } else {
            
            firstName = firstNameField.text!
            lastName = lastNameField.text!
            fullName = firstName + " " + lastName
            age = Int(ageField.text!)!
            email = emailField.text!
            
            UserDefaults.standard.set("\(fullName)", forKey: "fullName")
            UserDefaults.standard.set(age, forKey: "age")
            UserDefaults.standard.set("\(email)", forKey: "email")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "usernameAndPasswordVC")
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
            
        }
    }
}
