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
    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var noProjectsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var projectsArray = [Project]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My Projects"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        noProjectsLabel.text = "Loading..."
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        setupTableView()
        loadProjects()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProjects()
    }
    
    // MARK: - Load Projects
    let email = UserDefaults.standard.string(forKey: "email")
    func loadProjects() {
        if projectsArray.count > 0 {
            projectsArray.removeAll()
            tableView.reloadData()
        }
        
        db.collection("users").document("\(email!)").collection("projects").getDocuments() { [weak self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    let category = data["Category"] as? String ?? ""
                    let name = data["Creator Name"] as? String ?? ""
                    let date = data["Date Created"] as? String ?? ""
                    let email = data["Creator Email"] as? String ?? ""
                    let backgroundImageURL = data["Background Image URL"] as? String ?? nil
                    
                    let project = Project(title: title, email: email, name: name, date: date, category: category, backgroundImageURL: backgroundImageURL)
                    self?.projectsArray.append(project)
                    
                }
            }
            
            let filteredProjects = self?.projectsArray.filterDuplicates { $0.date == $1.date }
            
            if filteredProjects?.count != 0 {
                self?.noProjectsLabel.text = ""
                self?.projectsArray = filteredProjects!
            } else {
                self?.noProjectsLabel.text = "Create your first project now!"
            }
            
            self?.tableView.reloadData()
            self?.refreshControl.endRefreshing()
        }
    }
    
    // MARK: - Table View Delegates
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        let string = "Fetching projects..."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "AcherusGrotesque-Regular", size: 10)!,
        ]
        
        refreshControl.attributedTitle = NSAttributedString(string: string, attributes: attributes)
        refreshControl.backgroundColor = UIColor(named: "backgroundColors")
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
    }
    
    @objc private func refreshTableView(_ sender: Any) {
        loadProjects()
    }
    
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
        cell.textLabel?.text = project.title
        cell.textLabel?.textAlignment = .center
        cell.accessoryType = .disclosureIndicator
        
        return(cell)
    }
}
