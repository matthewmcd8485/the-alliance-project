//
//  ViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/9/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI
import FirebaseFirestore
import AuthenticationServices

class MainViewController: UIViewController {
    
    @IBOutlet var needLabel: UILabel!
    @IBOutlet var canLabel: UILabel!
    
    var user: User?
    
    let authUI = FUIAuth.defaultAuthUI()
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust custom color for the "I NEED HELP" label
        let needStringOne = "I NEED HELP"
        let needStringTwo = "NEED"
        let needRange = (needStringOne as NSString).range(of: needStringTwo)
        let needAttributedText = NSMutableAttributedString.init(string: needStringOne)
        needAttributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(named: "purpleColor")!, range: needRange)
        needLabel.attributedText = needAttributedText
        
        // Adjust custom color for the "I CAN HELP" label
        let canStringOne = "I CAN HELP"
        let canStringTwo = "CAN"
        let canRange = (canStringOne as NSString).range(of: canStringTwo)
        let canAttributedText = NSMutableAttributedString.init(string: canStringOne)
        canAttributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(named: "purpleColor")!, range: canRange)
        canLabel.attributedText = canAttributedText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showLoginIfNecessary()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.backItem?.backBarButtonItem?.tintColor = UIColor(named: "purpleColor")
    }
    
    func createSpinnerView() {
        let child = SpinnerViewController()
        
        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    // MARK: - Checking Credentials
    func checkForLaunchHistory() -> Bool {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore {
            return true
        } else {
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            return false
        }
    }
    
    func checkForLoginHistory() -> Bool {
        if UserDefaults.standard.bool(forKey: "loggedIn") == true {
            
            // Update the array of blocked users
            return true
        }
        
        return false
    }
    
    func showLoginIfNecessary() {
        let launchedBefore = checkForLaunchHistory()
        let loggedIn = checkForLoginHistory()
        
        if launchedBefore == false || loggedIn == false {
            print("User is not set up, showing login screen")
            
            createSpinnerView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboarding = storyboard.instantiateViewController(withIdentifier: "onboarding") as! OnboardingViewController
                self.navigationController?.pushViewController(onboarding, animated: true)
            })
            
        } else {
            let email = UserDefaults.standard.string(forKey: "email") ?? ""
            PushNotificationManager(userEmail: email).registerForPushNotifications()
            
            if let token = Messaging.messaging().fcmToken {
                UserDefaults.standard.setValue(token, forKey: "fcmToken")
            }
            
            DatabaseManager.shared.checkIfAccountIsDisabled(completion: { [weak self] success in
                if success {
                    print("User is already set up, no login process needed")
                } else {
                    let alert = UIAlertController(title: "Account disabled", message: "Your account has been disabled. All application activity will be suspended until the account is re-enabled.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        
                        do {
                            try self?.authUI?.signOut()
                        } catch {
                            print("Sign out process failed")
                        }
                        
                        Messaging.messaging().unsubscribe(fromTopic: "All users") { error in
                            print("Unsubscribed from notification topic: All users")
                        }
                        
                        UserDefaults.standard.set(false, forKey: "loggedIn")
                        UserDefaults.standard.set("", forKey: "authCredential")
                        UserDefaults.standard.set([""], forKey: "blockedUsers")
                        UserDefaults.standard.set("", forKey: "instagram")
                        UserDefaults.standard.set("", forKey: "twitter")
                        UserDefaults.standard.set("", forKey: "youtube")
                        UserDefaults.standard.set("", forKey: "website")
                        
                        self?.createSpinnerView()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let onboarding = storyboard.instantiateViewController(withIdentifier: "onboarding") as! OnboardingViewController
                            self?.navigationController?.pushViewController(onboarding, animated: true)
                        })
                    }))
                    self?.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
}

