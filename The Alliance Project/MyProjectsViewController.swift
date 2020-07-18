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

        noProjectsLabel.text = "Loading..."
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        loadProjects()
    
    }

    let username = UserDefaults.standard.string(forKey: "username")
    func loadProjects() {
        db.collection("users").document("\(username!)").collection("projects").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    self.numberOfProjectsOpen += 1
                    let data = document.data()
                    let title = data["Project Title"] as? String ?? ""
                    
                    self.projectsArray.append(title)
                    
                }
            }
            print("Number of projects open = \(self.numberOfProjectsOpen)")
            print(self.projectsArray)
            if self.projectsArray.count != 0 {
                self.noProjectsLabel.text = ""
            } else {
                self.noProjectsLabel.text = "Create your first project now!"
            }
            self.tableView.reloadData()

        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetails", sender: self)
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
        
        return(cell)
    }

    let fullName = UserDefaults.standard.string(forKey: "fullName")
    
    @IBAction func createButton(_ sender: Any) {
        if numberOfProjectsOpen >= 4 {
            let alert = UIAlertController(title: "Too many open projects", message: "You may only have 4 projects open at the same time.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "instructionsVC")
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ProjectEditViewController {
            destination.projectTitle = projectsArray[tableView.indexPathForSelectedRow!.row]
        }
    }
}
