//
//  ProjectEditViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ProjectEditViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    var projectTitle: String?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "PROJECT DETAILS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        loadDocument()
    }
    
    // MARK: - Load Project
    let email = UserDefaults.standard.string(forKey: "email")
    func loadDocument() {
        db.collection("users").document("\(email!)").collection("projects").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    let data = document.data()
                    if self.projectTitle == data["Project Title"] as? String {
                        self.titleLabel.text = self.projectTitle
                        self.dateLabel.text = "Created on \(data["Date Created"]!)"
                        self.descriptionLabel.text = data["Project Description"] as? String
                        self.categoryLabel.text = data["Category"] as? String
                        self.viewsLabel.text = "\(data["Views"]!) views"
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Project
    @IBAction func deleteButton(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Project", message: "This action cannot be undone. Are you sure that you want to do this?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete Project", style: .destructive, handler: {action in
            let db = Firestore.firestore()
            db.collection("users").document("\(self.email!)").collection("projects").document("\(self.projectTitle!)").delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Project successfully removed!")
                }
            }
            
            DispatchQueue.main.async {
                let count = self.navigationController?.viewControllers.count
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let homeScreen = storyboard.instantiateViewController(withIdentifier: "homeScreen") as! MainViewController
                self.navigationController?.pushViewController(homeScreen, animated: true)
                self.navigationController?.viewControllers.remove(at: count! - 1)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}
