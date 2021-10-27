//
//  NewProjectViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import UIKit

class NewProjectViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundDimView: UIView!
    @IBOutlet weak var pickACategoryLabel: UILabel!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var continueButtonLayer: UIButton!
    
    let alertManager = AlertManager.shared
    let profanityManager = ProfanityManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Project"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        descriptionView.delegate = self
        descriptionView.text = "Tell us a little bit about your project..."
        descriptionView.textColor = .lightGray
        
        titleField.delegate = self
        
        backgroundDimView.alpha = 0
        backgroundImageView.alpha = 0
        continueButtonLayer.layer.cornerRadius = 10
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        continueButtonLayer.layer.backgroundColor = UIColor(named: "imageButtonBackgroundColor")?.cgColor
    }
    
    // MARK: - Text Field Delgates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == "Tell us a little bit about your project...") {
            textView.text = ""
            if backgroundImageView.alpha == 0 {
                textView.textColor = UIColor(named: "labelColor")
            } else {
                textView.textColor = .white
            }
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Tell us a little bit about your project..."
            if backgroundImageView.alpha == 0 {
                textView.textColor = .lightGray
            } else {
                textView.textColor = .white
            }
        }
        textView.resignFirstResponder()
    }
    
    // MARK: - Adding Background Image
    @IBAction func addBackgroundButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "backgroundImageVC") as BackgroundImageViewController
        vc.completion = { [weak self] result in
            guard result.id != "" else {
                return
            }
            self?.photoResult = [result.urls.full, result.user.name, result.user.links.html]
            self?.configureImage(with: result.urls.full)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func configureImage(with urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        let token = "dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self?.backgroundImageView.image = image
                self?.backgroundDimView.isHidden = false
                self?.addAnImageLabel.textColor = .white
                self?.pickACategoryLabel.textColor = .white
                self?.addAnImageLabel.text = "Change the Background Image..."
                self?.continueButtonLayer.layer.backgroundColor = UIColor(named: "imageButtonBackgroundColor")?.cgColor
                self?.descriptionView.textColor = .white
                
                UIView.animate(withDuration: 0.5) {
                    self?.backgroundDimView.alpha = 0.5
                    self?.backgroundImageView.alpha = 1
                }
                
            }
        }.resume()
    }
    
    @IBAction func pickACategoryButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "categoryVC") as CategoryViewController
        vc.completion = { [weak self] result in
            guard !result.isEmpty else {
                return
            }
            self?.pickACategoryLabel.text = result
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    var projectTitle: String = ""
    var projectDescription: String = ""
    var photoResult: [String] = ["", "", ""]
    
    // MARK: - Saving Progress
    @IBAction func continueButton(_ sender: Any) {
        
        if descriptionView.text! == "Tell us a little bit about your project..." || titleField.text!.isEmpty || pickACategoryLabel.text == "Pick a Category... (required)" {
            alertManager.showAlert(title: "Some fields are still empty", message: "Please finish adding all of your information before continuing.")
        } else {

            var projectIsClear = true
            
            let titleContainsProfanity = profanityManager.checkForProfanity(in: titleField.text!)
            let descriptionContainsProfanity = profanityManager.checkForProfanity(in: descriptionView.text!)
            
            if titleContainsProfanity || descriptionContainsProfanity {
                projectIsClear = false
            }
            
            if projectIsClear {
                projectTitle = titleField.text!
                projectDescription = descriptionView.text!
                
                UserDefaults.standard.set(projectTitle, forKey: "projectTitle")
                UserDefaults.standard.set(projectDescription, forKey: "projectDescription")
                UserDefaults.standard.set(pickACategoryLabel.text, forKey: "projectCategory")
                UserDefaults.standard.set(photoResult, forKey: "photoResult")
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "uploadProjectVC")
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                alertManager.showAlert(title: "Inappropriate language", message: "There are some less-than-ideal words in your project. Please make it more appropriate.")
            }
        }
    }
}
