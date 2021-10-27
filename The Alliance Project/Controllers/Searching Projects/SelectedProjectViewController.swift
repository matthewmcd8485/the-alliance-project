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
    var creatorEmail: String?
    var dateCreated: String?
    var creatorFCMToken: String?
    
    @IBOutlet weak var unsplashProfileButton: UIButton!
    @IBOutlet weak var sendMessageLabel: UILabel!
    @IBOutlet weak var projectTitleLabel: UILabel!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var userDetailsButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundDimView: UIView!
    @IBOutlet weak var sendMessageIcon: UIImageView!
    @IBOutlet weak var viewCountIcon: UIImageView!
    @IBOutlet weak var descriptionIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Project Details"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "flag"), for: .normal)
        button.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        profileImageView.layer.cornerRadius = 10
        profileImageView.clipsToBounds = true
        profileImageView.alpha = 0
        backgroundImageView.alpha = 0
        backgroundDimView.alpha = 0
        unsplashProfileButton.alpha = 0

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
                                UIView.animate(withDuration: 0.5) {
                                    self?.profileImageView.alpha = 1
                                }
                                return
                            } else {
                                DispatchQueue.main.async {
                                    self?.profileImageView.sd_setImage(with: url!, completed: nil)
                                    UIView.animate(withDuration: 0.5) {
                                        self?.profileImageView.alpha = 1
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    // [0] = Image URL, [1] = Creator Name, and [2] = Creator Profile URL
    var backgroundImageStrings: [String] = [""]
    
    // MARK: - Loading Project
    func loadProjectData() {
        db.collection("users").document("\(creatorEmail!)").collection("projects").whereField("Project Title", isEqualTo: projectTitle!).whereField("Date Created", isEqualTo: dateCreated!).getDocuments() { [weak self] (querySnapshot, err) in
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
                        let fcmToken = document.get("Creator FCM Token") as? String
                        let date = document.get("Date Created") as! String
                        let projectID = document.get("Project ID") as? String ?? ""
                        let description = document.get("Project Description") as! String
                        let category = document.get("Category") as! String
                        let backgroundImageURL = document.get("Background Image URL") as? String ?? ""
                        let backgroundImageProfileURL = document.get("Background Image Creator Profile URL") as? String ?? ""
                        let backgroundImageUserName = document.get("Background Image Creator Name") as? String ?? ""
                        
                        strongSelf.creatorFCMToken = fcmToken
                        strongSelf.projectCreatorName = creatorName
                        
                        let project = Project(title: strongSelf.projectTitle!, email: strongSelf.creatorEmail!, name: creatorName, date: date, category: category, description: description, backgroundImageURL: backgroundImageURL, backgroundImageCreatorName: backgroundImageUserName, backgroundImageCreatorProfileURL: backgroundImageProfileURL, projectID: projectID)
                        
                        self?.backgroundImageStrings = [backgroundImageURL, backgroundImageUserName, backgroundImageProfileURL]
                        self?.updateUI(with: project)
                        
                        UserDefaults.standard.set(creatorName, forKey: "projectCreatorName")
                        
                        var views = document.get("Views") as! Int
                        views += 1
                        strongSelf.db.collection("users").document("\(strongSelf.creatorEmail!)").collection("projects").document("\(strongSelf.projectTitle!)").setData(["Views": views], merge: true)
                        if views == 1 {
                            strongSelf.viewsLabel.text = "1 view"
                        } else {
                            strongSelf.viewsLabel.text = "\(views) views"
                        }
                    }
                }
            }
        }
    }
    
    private func updateUI(with project: Project) {
        DispatchQueue.main.async { [weak self] in
            self?.projectTitleLabel.text = project.title
            self?.categoryLabel.text = project.category
            self?.dateCreatedLabel.text = "Created by \(project.name) on \(project.date)"
            self?.descriptionLabel.text = project.description
            
            self?.unsplashProfileButton.setTitle("Image by \(self?.backgroundImageStrings[1] ?? "") on Unsplash", for: .normal)

        }
        loadBackgroundImage(for: project.backgroundImageURL)
    }
    
    private func loadBackgroundImage(for url: String) {
        guard url != "" else {
            return
        }
        guard let imageURL = URL(string: url) else {
            return
        }
        
        let token = "dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        var request = URLRequest(url: imageURL)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self?.backgroundImageView.image = image
                
                UIView.animate(withDuration: 0.5) {
                    self?.backgroundDimView.alpha = 1
                    self?.backgroundImageView.alpha = 1
                    self?.viewsLabel.textColor = .white
                    self?.projectTitleLabel.textColor = UIColor(named: "lightPurpleColor")
                    self?.unsplashProfileButton.alpha = 1
                    self?.unsplashProfileButton.setTitleColor(UIColor(named: "lightPurpleColor"), for: .normal)
                    self?.descriptionLabel.textColor = .white
                    self?.categoryLabel.textColor = .white
                    self?.sendMessageLabel.textColor = .white
                    self?.descriptionIcon.tintColor = UIColor(named: "lightPurpleColor")
                    self?.viewCountIcon.tintColor = UIColor(named: "lightPurpleColor")
                    self?.sendMessageIcon.tintColor = UIColor(named: "lightPurpleColor")
                }
                
            }
        }.resume()
        
    }
    
    @IBAction func viewUnsplashProfileButton(_ sender: Any) {
        guard unsplashProfileButton.titleLabel?.text != "" else {
            return
        }
        
        let actionSheet = UIAlertController(title: "View \(backgroundImageStrings[1])'s Unsplash Profile", message: "This will send you outside of The Alliance Project. Continue?", preferredStyle: .actionSheet)
        actionSheet.addAction((UIAlertAction(title: "View \(backgroundImageStrings[1]) on Unsplash", style: .default, handler: { action in
            if let path = URL(string: "\(self.backgroundImageStrings[2])?utm_source=The-Alliance-Project&utm_medium=referral") {
                    UIApplication.shared.open(path, options: [:], completionHandler: nil)
            }
        })))
        actionSheet.addAction(UIAlertAction(title: "Visit the Unsplash homepage", style: .default, handler: { action in
            if let path = URL(string: "https://unsplash.com?utm_source=The-Alliance-Project&utm_medium=referral") {
                    UIApplication.shared.open(path, options: [:], completionHandler: nil)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
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
