//
//  ConversationsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 10/25/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private let refreshControl = UIRefreshControl()
    private var conversations = [Conversation]()
    
    @IBOutlet weak var nothingHereLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        
        nothingHereLabel.isHidden = true
        
        navigationItem.title = "Conversations"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "purpleColor")
        
        setupTableView()
        getAllConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // navigationController?.navigationBar.backItem?.backBarButtonItem?.tintColor = UIColor(named: "purpleColor")
    }
    
    @objc private func didTapComposeButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "newConversationsVC") as NewConversationViewController
        vc.completion = { [weak self] result in
            let currentConverastion = self?.conversations
            if let targetConversation = currentConverastion?.first(where: {
                $0.otherUserEmail == result["email"]
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.conversationID, fcmToken: targetConversation.fcmToken)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                UserDefaults.standard.setValue(targetConversation.name, forKey: "otherUserName")
                
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.createNewConversation(result: result)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Conversations
    private func getAllConversations() {
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        
        print("Starting conversation fetch...")
        DatabaseManager.shared.getAllConversations(for: email, currentConversations: conversations, completion: { [weak self] result in
            switch result {
            case .success(let newConversations):
                print("Successfully got conversation models")
                guard !newConversations.isEmpty else {
                    self?.hideTableView()
                    return
                }
                
                self?.conversations = newConversations
                
                DispatchQueue.main.async {
                    self?.showTableView()
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
            case .failure(let error):
                self?.hideTableView()
                print("Failed to get conversations: \(error)")
            }
        })
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
    
    // MARK: - User Interface Functions
    private func hideTableView() {
        tableView.isHidden = true
        nothingHereLabel.isHidden = false
    }
    
    private func showTableView() {
        tableView.isHidden = false
        nothingHereLabel.isHidden = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        let string = "Fetching conversations..."
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
        
        hideTableView()
    }
    
    @objc private func refreshTableView(_ sender: Any) {
        getAllConversations()
    }
}

// MARK: - Table View Delegates
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        
        cell.backgroundColor = UIColor(named: "backgroundColors")
        cell.textLabel?.font = UIFont(name: "AcherusGrotesque-Medium", size: 18)
        cell.textLabel?.textColor = UIColor(named: "purpleColor")
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.conversationID, fcmToken: model.fcmToken)
        vc.isNewConversation = false
        vc.title = model.name
        UserDefaults.standard.setValue(model.name, forKey: "otherUserName")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Begin delete
            let conversationID = conversations[indexPath.row].conversationID
            tableView.beginUpdates()
            DatabaseManager.shared.deleteConversation(conversationID: conversationID, completion: { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                } else {
                    return
                }
            })
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
