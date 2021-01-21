//
//  SelectedProjectViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/28/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation
import MessageUI

class SelectedProjectViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let db = Firestore.firestore()
    let alertManager = AlertManager.shared
    
    var projectTitle: String?
    var projectCreatorName: String?
    var projectCategory: String?
    var creatorEmail: String?
    var creatorFCMToken: String?
    
    @IBOutlet weak var projectTitleLabel: UILabel!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var interestedInHelpingLabel: UILabel!
    @IBOutlet weak var userDetailsButton: UIButton!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "PROJECT DETAILS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "flag"), for: .normal)
        button.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.isHidden = true
        
        projectCreatorName = UserDefaults.standard.string(forKey: "projectCreatorName")
        creatorEmail = UserDefaults.standard.string(forKey: "creatorEmail")
        projectTitle = UserDefaults.standard.string(forKey: "projectTitle")
        
        loadUserImage()
        loadProjectData()
        
    }
    
    // MARK: - Reporting Project
    @objc func didTapInfoButton() {
        let currentEmail = UserDefaults.standard.string(forKey: "email")
        let alert = UIAlertController(title: "Flag project", message: "You can flag a project for being inappropriate, spam, offensive, etc. Flagged projects will be removed from The Alliange Project if they are deemed inappropriate or offensive in any way.", preferredStyle: .actionSheet)
        
        // Report as inappropriate
        alert.addAction(UIAlertAction(title: "Report project as inappropriate", style: .default, handler: { [weak self] action in
            if self?.creatorEmail == currentEmail {
                self?.alertManager.showAlert(title: "Hold up!", message: "You can't report your own project. Nice try, though!")
            } else {
                let date = FormatDate.dateFormatter.string(from: Date())
                ReportingManager.shared.reportProject(with: (self?.creatorEmail)!, title: (self?.projectTitle)!, description: (self?.descriptionLabel.text)!, date: date, kind: "Inappropriate", completion: { success in
                    if success {
                        DispatchQueue.main.async {
                            self?.alertManager.showAlert(title: "Thank you", message: "Your report has been received. Thank you for helping us maintain a safe and inclusive community on The Alliance Project.")
                        }
                    }
                })
            }
        }))
        
        // Report as spam
        alert.addAction(UIAlertAction(title: "Report project as spam", style: .default, handler: { [weak self] action in
            if self?.creatorEmail == currentEmail {
                self?.alertManager.showAlert(title: "Hold up!", message: "You can't report your own project. Nice try, though!")
            } else {
                let date = FormatDate.dateFormatter.string(from: Date())
                ReportingManager.shared.reportProject(with: (self?.creatorEmail)!, title: (self?.projectTitle)!, description: (self?.descriptionLabel.text)!, date: date, kind: "Spam", completion: { success in
                    if success {
                        DispatchQueue.main.async {
                            self?.alertManager.showAlert(title: "Thank you", message: "Your report has been received. Thank you for helping us maintain a safe and inclusive community on The Alliance Project.")
                        }
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Loading User Image
    func loadUserImage() {
        db.collection("users").whereField("Email Address", isEqualTo: creatorEmail!).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting user documents: \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    let alert = UIAlertController(title: "Creator image not found", message: "The creator's profile image could not be found. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        let email = document.get("Email Address") as! String
                        let profileImageURL: String = document.get("Profile Image URL") as! String
                        print(profileImageURL)
                        
                        // Look for user's profile image
                        let storageRef = Storage.storage().reference().child("profile images").child("\(email) - profile image.png")
                        storageRef.downloadURL(completion: { [weak self] (url, error) in
                            if error != nil {
                                print("Failed to download user's profile url:", error!)
                                // Image does not exist
                                self?.profileImageView.isHidden = false
                                return
                            } else {
                                DispatchQueue.main.async {
                                    self?.profileImageView.sd_setImage(with: url!, completed: nil)
                                    self?.profileImageView.isHidden = false
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Loading Project
    func loadProjectData() {
        db.collection("users").document("\(creatorEmail!)").collection("projects").whereField("Project Title", isEqualTo: projectTitle!).getDocuments() { [weak self] (querySnapshot, err) in
            guard let strongSelf = self else {
                return
            }
            if let err = err {
                print("Error getting project documents: \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    let alert = UIAlertController(title: "Project not found", message: "The project selected could not be found. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    strongSelf.present(alert, animated: true, completion: nil)
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        let creatorName = document.get("Creator Name") as! String
                        strongSelf.projectCreatorName = creatorName
                        strongSelf.creatorFCMToken = document.get("Creator FCM Token") as? String
                        
                        UserDefaults.standard.set(creatorName, forKey: "projectCreatorName")
                        
                        var views = document.get("Views") as! Int
                        views += 1
                        strongSelf.db.collection("users").document("\(strongSelf.creatorEmail!)").collection("projects").document("\(strongSelf.projectTitle!)").setData(["Views": views], merge: true)
                        if views == 1 {
                            strongSelf.viewsLabel.text = "1 view"
                        } else {
                            strongSelf.viewsLabel.text = "\(views) views"
                        }
                        
                        strongSelf.projectCategory = document.get("Category") as? String
                        
                        strongSelf.projectTitleLabel.text = document.get("Project Title") as? String
                        strongSelf.categoryLabel.text = document.get("Category") as? String
                        strongSelf.dateCreatedLabel.text = "Created by \(strongSelf.projectCreatorName!) on \(document.get("Date Created")!)"
                        strongSelf.descriptionLabel.text = document.get("Project Description") as? String
                        strongSelf.interestedInHelpingLabel.text = "Interested in helping? Let \(strongSelf.projectCreatorName!) know!"
                    }
                }
            }
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.performSegue(withIdentifier: "backToSearchSegue", sender: nil)
    }
    
    // MARK: - Creating Conversation
    @IBAction func iWantInButton(_ sender: Any) {
        print(creatorEmail!)
        if creatorEmail! == UserDefaults.standard.string(forKey: "email") {
            alertManager.showAlert(title: "Hold up!", message: "Unfortunately, you can't start a conversation with yourself. Keep those thoughts in your head!")
        } else {
            let userData: [String: String] = ["name" : self.projectCreatorName!, "email" : self.creatorEmail!, "fcmToken" : self.creatorFCMToken!]
            createNewConversation(result: userData)
        }
    }
    
    private func createNewConversation(result: [String: String]) {
        // "name" variable is the name of the second user
        guard let name = result["name"], let email = result["email"], let fcmToken = result["fcmToken"] else {
            return
        }
        
        // Check in database if conversation between these two users already exists
        // If it does, reuse conversation ID
        // Otherise, use existing code
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationID):
                let vc = ChatViewController(with: email, id: conversationID, fcmToken: fcmToken)
                vc.isNewConversation = false
                vc.title = name
                UserDefaults.standard.setValue(name, forKey: "otherUserName")
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil, fcmToken: fcmToken)
                vc.isNewConversation = true
                vc.title = name
                UserDefaults.standard.setValue(name, forKey: "otherUserName")
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    // MARK: - View Profile
    @IBAction func viewProfileButton(_ sender: Any) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "userDetailsVC") as? UserDetailsViewController
            else { return }
            viewController.projectCreatorEmail = self.creatorEmail
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
