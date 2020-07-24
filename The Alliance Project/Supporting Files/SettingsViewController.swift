//
//  SettingsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 8/1/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteDataButton.titleLabel?.numberOfLines = 2
        deleteDataButton.titleLabel?.lineBreakMode = .byWordWrapping
    }
    
    @IBOutlet weak var deleteDataButton: UIButton!
    
    @IBAction func viewSettings(_ sender: Any) {
        UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func privacyPolicy(_ sender: Any) {
        guard let url = URL(string: "https://matthewdevteam.weebly.com/privacy.html") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure that you want to log out?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: {action in
            UserDefaults.standard.set(false, forKey: "loggedIn")
            
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "firstOnboardingActualScreen") as? firstOnboardingViewController
                    else { return }
                viewController.modalPresentationStyle = .formSheet
                viewController.isModalInPresentation = true
                self.present(viewController, animated: true, completion: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteUserDataButton(_ sender: Any) {
        let alert = UIAlertController(title: "Delete User Data", message: "Deleting user data will completely destroy your user account. Are you sure that you want to do this?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out Normally", style: .default, handler: {action in
            UserDefaults.standard.set(false, forKey: "loggedIn")
            UserDefaults.standard.set("", forKey: "instagram")
            UserDefaults.standard.set("", forKey: "twitter")
            UserDefaults.standard.set("", forKey: "youtube")
            UserDefaults.standard.set("", forKey: "website")
            
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "firstOnboardingActualScreen") as? firstOnboardingViewController
                    else { return }
                viewController.modalPresentationStyle = .formSheet
                viewController.isModalInPresentation = true
                self.present(viewController, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Log Out & Delete User Data", style: .destructive, handler: {action in
            UserDefaults.standard.set(false, forKey: "loggedIn")
            
            let fullName = UserDefaults.standard.string(forKey: "fullName")
            let db = Firestore.firestore()
            db.collection("users").document("\(fullName!)").delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                    
                    UserDefaults.standard.set("", forKey: "instagram")
                    UserDefaults.standard.set("", forKey: "twitter")
                    UserDefaults.standard.set("", forKey: "youtube")
                    UserDefaults.standard.set("", forKey: "website")
                }
            }
            
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "firstOnboardingActualScreen") as? firstOnboardingViewController
                    else { return }
                viewController.modalPresentationStyle = .formSheet
                viewController.isModalInPresentation = true
                self.present(viewController, animated: true, completion: nil)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func writeReviewButton(_ sender: Any) {
        let alert = UIAlertController(title: "Hold Tight!", message: "You can't leave a review until the app is live on the App Store. Until then, feel free to send some beta app feedback through TestFlight!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

