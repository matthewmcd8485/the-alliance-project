//
//  NewProjectViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import UIKit

class NewProjectViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var titleField: UITextField!
    let alertManager = AlertManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "NEW PROJECT"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        descriptionView.delegate = self
        descriptionView.text = "Tell us a little bit about your project..."
        descriptionView.textColor = .lightGray
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Text Field Delgates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        if (textView.text == "Tell us a little bit about your project..." && textView.textColor == .lightGray)
        {
            textView.text = ""
            textView.textColor = UIColor(named: "labelColor")
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        if (textView.text == "")
        {
            textView.text = "Tell us a little bit about your project..."
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
    
    
    var projectTitle: String = ""
    var projectDescription: String = ""
    
    // MARK: - Saving Progress
    let blockedWords = BlockedWords.shared.blockedWords()
    @IBAction func continueButton(_ sender: Any) {
        
        if descriptionView.text! == "Tell us a little bit about your project..." || titleField.text!.isEmpty {
            alertManager.showAlert(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.")
        } else {
            guard !blockedWords.isEmpty else {
                alertManager.showAlert(title: "Something's gone wrong", message: "There was an error when checking the details of your project. Please try again.")
                return
            }
            var projectIsClear = true
            
            // Check the strings for bad words in the array
            var titleContains = false
            var descriptionContains = false
            
            let titleArray = titleField.text!.components(separatedBy: " ")
            let descriptionArray = descriptionView.text!.components(separatedBy: " ")
            for badWord in blockedWords {
                for word in titleArray {
                    if word.lowercased() == badWord {
                        titleContains = true
                    }
                }
            }
            
            for badWord in blockedWords {
                for word in descriptionArray {
                    if word.lowercased() == badWord {
                        descriptionContains = true
                    }
                }
            }
            
            if titleContains || descriptionContains {
                projectIsClear = false
            }
            
            if projectIsClear {
                projectTitle = titleField.text!
                projectDescription = descriptionView.text!
                
                UserDefaults.standard.set(projectTitle, forKey: "projectTitle")
                UserDefaults.standard.set(projectDescription, forKey: "projectDescription")
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "specificsVC")
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                alertManager.showAlert(title: "Inappropriate language", message: "There are some less-than-ideal words in your project. Please make it more appropriate.")
            }
        }
    }
}
