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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionView.delegate = self
        descriptionView.text = "Tell us a little bit about your project..."
        descriptionView.textColor = .lightGray
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
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
    
    @IBAction func continueButton(_ sender: Any) {
        
        if descriptionView.text! == "Tell us a little bit about your project..." || titleField.text!.isEmpty {
            let alert = UIAlertController(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            projectTitle = titleField.text!
            projectDescription = descriptionView.text!
            
            UserDefaults.standard.set(projectTitle, forKey: "projectTitle")
            UserDefaults.standard.set(projectDescription, forKey: "projectDescription")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "specificsVC")
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }
    }
}
