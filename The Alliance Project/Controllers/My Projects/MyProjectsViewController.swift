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
        tableView.register(MyProjectTableViewCell.self, forCellReuseIdentifier: MyProjectTableViewCell.identifier)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        setupTableView()
        loadProjects()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Load Projects
    let email = UserDefaults.standard.string(forKey: "email")
    func loadProjects() {
        
        db.collection("users").document("\(email!)").collection("projects").getDocuments() { [weak self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self?.projectsArray.removeAll()
                for document in querySnapshot!.documents {
                    
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    let category = data["Category"] as? String ?? ""
                    let name = data["Creator Name"] as? String ?? ""
                    let date = data["Date Created"] as? String ?? ""
                    let email = data["Creator Email"] as? String ?? ""
                    let backgroundImageURL = data["Background Image URL"] as? String ?? ""
                    let projectID = data["Project ID"] as? String ?? ""
                    
                    let project = Project(title: title, email: email, name: name, date: date, category: category, description: "", backgroundImageURL: backgroundImageURL, backgroundImageCreatorName: "", backgroundImageCreatorProfileURL: "", projectID: projectID)
                    self?.projectsArray.append(project)
                }
            }
          
            if self?.projectsArray.count != 0 {
                self?.noProjectsLabel.text = ""
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "projectEditVC") as! ProjectEditViewController
        vc.projectTitle = projectsArray[indexPath.row].title
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projectsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = projectsArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: MyProjectTableViewCell.identifier, for: indexPath) as! MyProjectTableViewCell
        cell.backgroundColor = UIColor(named: "backgroundColors")
        cell.accessoryType = .disclosureIndicator
        cell.contentView.clipsToBounds = true
        cell.configure(with: model)
        return cell
    }
}
