//
//  MyProjectsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class InstructionsViewController: UIViewController {}

class MyProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var noProjectsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var projectsArray = [String]()
    var numberOfProjectsOpen: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MY PROJECTS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        noProjectsLabel.text = "Loading..."
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        
        loadProjects()
        
    }
    
    // MARK: - Load Projects
    let email = UserDefaults.standard.string(forKey: "email")
    func loadProjects() {
        db.collection("users").document("\(email!)").collection("projects").getDocuments() { [weak self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    self?.numberOfProjectsOpen += 1
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    
                    self?.projectsArray.append(title)
                    
                }
            }
            if self?.projectsArray.count != 0 {
                self?.noProjectsLabel.text = ""
            } else {
                self?.noProjectsLabel.text = "Create your first project now!"
            }
            self?.tableView.reloadData()
            
        }
    }
    
    // MARK: - Table View Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "projectEditVC") as! ProjectEditViewController
        vc.projectTitle = cell?.textLabel?.text
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projectsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let project = projectsArray[indexPath.row]
        cell.textLabel?.font = UIFont(name:"AcherusGrotesque-Light", size: 30)
        cell.textLabel?.textColor = UIColor(named: "purpleColor")
        cell.backgroundColor = UIColor(named: "backgroundColors")
        cell.textLabel?.text = project
        cell.textLabel?.textAlignment = .center
        cell.accessoryType = .disclosureIndicator
        
        return(cell)
    }
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    
    // MARK: - Create New Project
    @IBAction func createButton(_ sender: Any) {
        if numberOfProjectsOpen >= 4 {
            let alert = UIAlertController(title: "Too many open projects", message: "You may only have 4 projects open at the same time.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "instructionsVC")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ProjectEditViewController {
            destination.projectTitle = projectsArray[tableView.indexPathForSelectedRow!.row]
        }
    }
}
