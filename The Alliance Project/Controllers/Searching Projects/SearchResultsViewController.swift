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
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noProjectsLabel: UILabel!
    
    let db = Firestore.firestore()
    var projectsArray = [String]()
    var creatorNamesArray = [String]()
    var creatorEmailsArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SEARCH RESULTS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        categoryLabel.text = "Category: \(category!)"
        noProjectsLabel.text = "Loading projects..."
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        loadProjects()
    }
    
    func loadProjects() {
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
                
                // Check if the project's creator is blocked
                if !ReportingManager.shared.userIsBlocked(for: creatorEmail) {
                    strongSelf.projectsArray.append(title)
                    strongSelf.creatorNamesArray.append(creatorName)
                    strongSelf.creatorEmailsArray.append(creatorEmail)
                }
            }
            if strongSelf.projectsArray.count != 0 {
                strongSelf.noProjectsLabel.text = ""
            } else {
                strongSelf.noProjectsLabel.text = "No projects under the given category."
            }
            strongSelf.tableView.reloadData()
        }
    }
    
    // MARK: - Table View Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetails", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projectsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let project = projectsArray[indexPath.row]
        cell.textLabel?.font = UIFont(name:"AcherusGrotesque-Light", size: 22)
        cell.textLabel?.textColor = UIColor(named: "purpleColor")
        cell.backgroundColor = UIColor(named: "backgroundColors")
        cell.textLabel?.text = project
        cell.detailTextLabel?.text = "detail"
        cell.textLabel?.textAlignment = .center
        
        return(cell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SelectedProjectViewController {
            UserDefaults.standard.set(creatorEmailsArray[tableView.indexPathForSelectedRow!.row], forKey: "creatorEmail")
            UserDefaults.standard.set(projectsArray[tableView.indexPathForSelectedRow!.row], forKey: "projectTitle")
            
            destination.projectTitle = projectsArray[tableView.indexPathForSelectedRow!.row]
            destination.projectCreatorName = creatorNamesArray[tableView.indexPathForSelectedRow!.row]
            destination.creatorEmail = creatorEmailsArray[tableView.indexPathForSelectedRow!.row]
        }
    }
}
