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
    
    var projectTitle: String?
    var projectCreatorName: String?
    var projectCreatorUsername: String?
    var projectCategory: String?
    var creatorEmail: String?
    
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

        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        
        projectCreatorUsername = UserDefaults.standard.string(forKey: "selectedProjectUsername")
        projectTitle = UserDefaults.standard.string(forKey: "projectTitle")
        
        loadUserImage()
        loadProjectData()
        
    }
    
    
    func loadUserImage() {
        db.collection("users").whereField("Username", isEqualTo: projectCreatorUsername!).getDocuments() { (querySnapshot, err) in
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
                        
                        let username = document.get("Username")
                        let profileImageURL: String = document.get("Profile Image URL") as! String
                        print(profileImageURL)
                        
                        // download picture from storage
                        // save picture to device
                        if profileImageURL != "No profile picture yet" {
                            let storageRef = Storage.storage().reference(withPath: "profile images/\(username!) - profile image.png")
                            storageRef.getData(maxSize: 2 * 2048 * 2048) { data, error in
                                if let error = error {
                                    print(error)
                                } else {
                                    // Data for profile image is returned
                                    print("data = \(data!)")
                                    let placeholderImage = UIImage(named: "Onboarding1.jpg")
                                    self.profileImageView.sd_setImage(with: storageRef, placeholderImage: placeholderImage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadProjectData() {
        db.collection("users").document("\(projectCreatorUsername!)").collection("projects").whereField("Project Title", isEqualTo: projectTitle!).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting project documents: \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    let alert = UIAlertController(title: "Project not found", message: "The project selected could not be found. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        var views = document.get("Views") as! Int
                        views += 1
                        self.db.collection("users").document("\(self.projectCreatorUsername!)").collection("projects").document("\(self.projectTitle!)").setData(["Views": views], merge: true)
                        if views == 1 {
                            self.viewsLabel.text = "1 view"
                        } else {
                            self.viewsLabel.text = "\(views) views"
                        }
                        
                        self.projectCategory = document.get("Category") as? String
                        self.creatorEmail = document.get("Creator Email") as? String
                        
                        self.projectTitleLabel.text = document.get("Project Title") as? String
                        self.categoryLabel.text = document.get("Category") as? String
                        self.dateCreatedLabel.text = "Created by \(self.projectCreatorUsername!) on \(document.get("Date Created")!)"
                        self.descriptionLabel.text = document.get("Project Description") as? String
                        self.interestedInHelpingLabel.text = "Interested in helping? Let \(self.projectCreatorUsername!) know!"
                    }
                }
            }
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.performSegue(withIdentifier: "backToSearchSegue", sender: nil)
    }
    
    @IBAction func iWantInButton(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            let alert = UIAlertController(title: "Emailing not supported", message: "Your device is not set up for emailing. Please check your email preferences and try again.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self

        let yourUsername = UserDefaults.standard.string(forKey: "username")
        let fullName = UserDefaults.standard.string(forKey: "fullName")
        composeVC.setToRecipients([creatorEmail!])
        composeVC.setSubject("The Alliance Project - \(yourUsername!) Wants to Help You!")
        composeVC.setMessageBody("Heyo! </br> </br> I found your project \"\(projectTitle!)\" on The Alliance Project and really want to help you! </br> </br> Let me know what I can do to get started. </br> </br> Thanks! </br> - \(fullName!)", isHTML: true)

        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SearchResultsViewController {
            destination.category = projectCategory
        }
        if let destination = segue.destination as? UserDetailsViewController {
            destination.projectCreatorEmail = creatorEmail!
        }
    }
}
