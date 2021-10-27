//
//  SearchResultsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/28/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation

class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var category: String?
    var keyword: String?
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noProjectsLabel: UILabel!
    
    let db = Firestore.firestore()
    
    private var results = [Project]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProjectSearchTableViewCell.self, forCellReuseIdentifier: ProjectSearchTableViewCell.identifier)
        
        navigationItem.title = "Search Results"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if category != nil {
            loadProjectsByCategory()
        } else if keyword != nil {
            loadProjectsByKeyword()
        }
        
    }
    
    private func loadProjectsByCategory() {
        noProjectsLabel.text = "Loading projects..."
        if category == "All Projects" {
            // Load all projects
            categoryLabel.text = "Showing all open projects"
            db.collectionGroup("projects").getDocuments() { [weak self] (snapshot, error) in
                guard let strongSelf = self else {
                    return
                }
                
                if error != nil {
                    print("error retrieving project documents: ", error!)
                }
                for document in snapshot!.documents {
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    let creatorName = data["Creator Name"] as? String ?? ""
                    let creatorEmail = data["Creator Email"] as? String ?? ""
                    let projectCategory = data["Category"] as? String ?? ""
                    let date = data["Date Created"] as? String ?? ""
                    let backgroundImageURL = data["Background Image URL"] as? String ?? ""
                    let projectID = data["Project ID"] as? String ?? ""
                    
                    // Check if the project's creator is blocked
                    if !ReportingManager.shared.userIsBlocked(for: creatorEmail) {
                        let project = Project(title: title, email: creatorEmail, name: creatorName, date: date, category: projectCategory, description: "", backgroundImageURL: backgroundImageURL, backgroundImageCreatorName: "", backgroundImageCreatorProfileURL: "", projectID: projectID)
                        print(project)
                        if !project.isBlank() {
                            strongSelf.results.append(project)
                        }
                    }
                }
                if strongSelf.results.count != 0 {
                    strongSelf.noProjectsLabel.text = ""
                } else {
                    strongSelf.noProjectsLabel.text = "No projects found."
                }
                strongSelf.tableView.reloadData()
            }
        } else {
            // Load projects for only a certain category
            categoryLabel.text = "Category: \(category!)"
            db.collectionGroup("projects").whereField("Category", isEqualTo: category!).getDocuments() { [weak self] (snapshot, error) in
                guard let strongSelf = self else {
                    return
                }
                
                if error != nil {
                    print("error retrieving project documents: ", error!)
                }
                for document in snapshot!.documents {
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    let creatorName = data["Creator Name"] as? String ?? ""
                    let creatorEmail = data["Creator Email"] as? String ?? ""
                    let date = data["Date Created"] as? String ?? ""
                    let backgroundImageURL = data["Background Image URL"] as? String ?? ""
                    let projectID = data["Project ID"] as? String ?? ""
                    
                    // Check if the project's creator is blocked
                    if !ReportingManager.shared.userIsBlocked(for: creatorEmail) {
                        let project = Project(title: title, email: creatorEmail, name: creatorName, date: date, category: "", description: "", backgroundImageURL: backgroundImageURL, backgroundImageCreatorName: "", backgroundImageCreatorProfileURL: "", projectID: projectID)
                        strongSelf.results.append(project)
                    }
                }
                if strongSelf.results.count != 0 {
                    strongSelf.noProjectsLabel.text = ""
                } else {
                    strongSelf.noProjectsLabel.text = "No projects under the given category."
                }
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    private func loadProjectsByKeyword() {
        // Load projects by user's search keyword
        categoryLabel.text = "Search term: \(keyword!)"
        let endChar = Character(UnicodeScalar((keyword?.last?.asciiValue)! + 1))
        var newKeyword = String(keyword!.dropLast())
        newKeyword.append(endChar)
        
        db.collectionGroup("projects").whereField("Project Title", isGreaterThan: keyword!).whereField("Project Title", isLessThan: newKeyword ).getDocuments() { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            
            if error != nil {
                print("error retrieving project documents: ", error!)
            }
            for document in snapshot!.documents {
                let data = document.data()
                let title = data["Project Title"] as? String ?? ""
                let creatorName = data["Creator Name"] as? String ?? ""
                let creatorEmail = data["Creator Email"] as? String ?? ""
                let date = data["Date Created"] as? String ?? ""
                let projectCategory = data["Category"] as? String ?? ""
                let backgroundImageURL = data["Background Image URL"] as? String ?? ""
                let projectID = data["Project ID"] as? String ?? ""
                
                // Check if the project's creator is blocked
                if !ReportingManager.shared.userIsBlocked(for: creatorEmail) {
                    let project = Project(title: title, email: creatorEmail, name: creatorName, date: date, category: projectCategory, description: "", backgroundImageURL: backgroundImageURL, backgroundImageCreatorName: "", backgroundImageCreatorProfileURL: "", projectID: projectID)
                    strongSelf.results.append(project)
                }
            }
            if strongSelf.results.count != 0 {
                strongSelf.noProjectsLabel.text = ""
            } else {
                strongSelf.noProjectsLabel.text = "No projects under the given search terms."
            }
            strongSelf.tableView.reloadData()
        }
    }
    
    // MARK: - Table View Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let project = results[indexPath.row]
        
        UserDefaults.standard.set(project.email, forKey: "creatorEmail")
        UserDefaults.standard.set(project.title, forKey: "projectTitle")
        
        performSegue(withIdentifier: "showDetails", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProjectSearchTableViewCell.identifier, for: indexPath) as! ProjectSearchTableViewCell
        cell.textLabel?.font = UIFont(name: "AcherusGrotesque-Medium", size: 18)
        cell.textLabel?.textColor = UIColor(named: "purpleColor")
        cell.backgroundColor = UIColor(named: "backgroundColors")
        cell.accessoryType = .disclosureIndicator
        cell.configure(with: model)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SelectedProjectViewController {
            UserDefaults.standard.set(results[tableView.indexPathForSelectedRow!.row].email, forKey: "creatorEmail")
            UserDefaults.standard.set(results[tableView.indexPathForSelectedRow!.row].title, forKey: "projectTitle")
            UserDefaults.standard.set(results[tableView.indexPathForSelectedRow!.row].date, forKey: "dateCreated")
            
            destination.projectTitle = results[tableView.indexPathForSelectedRow!.row].title
            destination.dateCreated = results[tableView.indexPathForSelectedRow!.row].date
            destination.creatorEmail = results[tableView.indexPathForSelectedRow!.row].email
        }
    }
}
