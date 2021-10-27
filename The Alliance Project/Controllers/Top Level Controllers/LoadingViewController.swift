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
import FirebaseAuthUI
import FirebaseFirestore
import FirebaseCrashlytics
import JGProgressHUD
import AuthenticationServices

class LoadingViewController: UIViewController {
    
    var user: User?
    let authUI = FUIAuth.defaultAuthUI()
    
    @IBOutlet weak var logoImage: UIImageView!
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes

    }
    
    override func viewDidAppear(_ animated: Bool) {
        createSpinnerView()
        showLoginIfNecessary()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.navigationBar.backItem?.backBarButtonItem?.tintColor = UIColor(named: "purpleColor")
    }
    
    func createSpinnerView() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.frame = CGRect(x: view.center.x - 10, y: logoImage.bottom + 40, width: 20, height: 20)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        //spinner.hudView.frame = CGRect(x: view.center.x, y: view.center.y - 120, width: 50, height: 50)
        //spinner.show(in: view)
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
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    func showLoginIfNecessary() {
        let launchedBefore = checkForLaunchHistory()
        let loggedIn = checkForLoginHistory()
        
        if launchedBefore == false || loggedIn == false {
            print("User is not set up, showing login screen")
            
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let onboarding = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! TabBarController
                        self?.navigationController?.pushViewController(onboarding, animated: true)
                    })
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
                        UserDefaults.standard.set(false, forKey: "locationErrorDismissal")
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

