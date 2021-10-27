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
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundDimView: UIView!
    @IBOutlet weak var descriptionIcon: UIImageView!
    @IBOutlet weak var categoryIcon: UIImageView!
    @IBOutlet weak var viewsIcon: UIImageView!
    @IBOutlet weak var unsplashButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Project Details"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let trashButton: UIButton = UIButton(type: .custom)
        trashButton.setImage(UIImage(systemName: "trash"), for: .normal)
        trashButton.tintColor = .red
        trashButton.addTarget(self, action: #selector(deleteProject), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: trashButton)
        navigationItem.rightBarButtonItem = barButton
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        backgroundImageView.alpha = 0
        backgroundDimView.alpha = 0
        
        unsplashButton.alpha = 0
        
        loadDocument()
    }
    
    // MARK: - Load Project
    let email = UserDefaults.standard.string(forKey: "email")
    func loadDocument() {
        db.collection("users").document("\(email!)").collection("projects").getDocuments() { [weak self] (querySnapshot, err) in
            guard let strongSelf = self else {
                return
            }
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    let data = document.data()
                    if strongSelf.projectTitle == data["Project Title"] as? String {
                        strongSelf.titleLabel.text = strongSelf.projectTitle
                        strongSelf.dateLabel.text = "Created on \(data["Date Created"]!)"
                        strongSelf.descriptionLabel.text = data["Project Description"] as? String
                        strongSelf.categoryLabel.text = data["Category"] as? String
                        
                        let views = data["Views"] as? Int ?? 0
                        if views == 1 {
                            strongSelf.viewsLabel.text = "\(views) view"
                        } else {
                            strongSelf.viewsLabel.text = "\(views) views"
                        }
                        
                        let backgroundImageURL = data["Background Image URL"] as? String ?? ""
                        let backgroundImageName = data["Background Image Creator Name"] as? String ?? "[Unknown User]"
                        let backgroundImageProfileLink = data["Background Image Creator Profile URL"] as? String ?? "https://www.unsplash.com"
                        
                        strongSelf.backgroundImageStrings = [backgroundImageURL, backgroundImageName, backgroundImageProfileLink]
                        strongSelf.unsplashButton.setTitle("Image by \(backgroundImageName) on Unsplash", for: .normal)
                        
                        if backgroundImageURL != "" {
                            strongSelf.loadBackgroundImage(for: backgroundImageURL)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Background Image
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
                    self?.dateLabel.textColor = .white
                    self?.descriptionLabel.textColor = .white
                    self?.categoryLabel.textColor = .white
                    self?.viewsIcon.tintColor = UIColor(named: "lightPurpleColor")
                    self?.descriptionIcon.tintColor = UIColor(named: "lightPurpleColor")
                    self?.categoryIcon.tintColor = UIColor(named: "lightPurpleColor")
                    self?.titleLabel.textColor = UIColor(named: "lightPurpleColor")
                    self?.unsplashButton.alpha = 1
                    self?.unsplashButton.setTitleColor(UIColor(named: "lightPurpleColor"), for: .normal)
                }
                
            }
        }.resume()
    }
    
    // [0] = Image URL, [1] = Creator Name, and [2] = Creator Profile URL
    var backgroundImageStrings: [String] = ["", "", ""]
    
    @IBAction func viewUnsplashProfileButton(_ sender: Any) {
        if backgroundImageStrings[1] == "[Unknown User]" {
            let actionSheet = UIAlertController(title: "Visit the Unsplash Website", message: "There was an issue loading the background image creator's info, so we have to redirect you to Unsplash's home page instead. This will send you outside of The Alliance Project. Continue?", preferredStyle: .actionSheet)
            actionSheet.addAction((UIAlertAction(title: "Visit the Unsplash website", style: .default, handler: { action in
                if let path = URL(string: "https://www.unsplash.com") {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            })))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: "View \(backgroundImageStrings[1])'s Unsplash Profile", message: "This will send you outside of The Alliance Project. Continue?", preferredStyle: .actionSheet)
            actionSheet.addAction((UIAlertAction(title: "View \(backgroundImageStrings[1]) on Unsplash", style: .default, handler: { action in
                if let path = URL(string: self.backgroundImageStrings[2]) {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            })))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    // MARK: - Delete Project
    @objc private func deleteProject() {
        let alert = UIAlertController(title: "Delete Project", message: "This action cannot be undone. Are you sure that you want to do this?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete Project", style: .destructive, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            strongSelf.db.collection("users").document("\(strongSelf.email!)").collection("projects").document("\(strongSelf.projectTitle!)").delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Project successfully removed!")
                }
            }
            
            DispatchQueue.main.async {
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}
