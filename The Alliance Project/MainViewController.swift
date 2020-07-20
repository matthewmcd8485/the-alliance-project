//
//  ViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/9/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import AuthenticationServices

class MainNavigationController: UINavigationController { }

class MainViewController: UIViewController {

    @IBOutlet var needLabel: UILabel!
    @IBOutlet var canLabel: UILabel!
    
    var user: User?
    
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
            return true
        }
        
        return false
    }
    
    func showLoginIfNecessary() {
        let launchedBefore = checkForLaunchHistory()
        let loggedIn = checkForLoginHistory()
        
        if launchedBefore == false || loggedIn == false {
            print("user is not set up, showing login screen")
            
            createSpinnerView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboarding = storyboard.instantiateViewController(withIdentifier: "firstOnboardingActualScreen") as! firstOnboardingViewController
                onboarding.modalPresentationStyle = .fullScreen
                self.present(onboarding, animated: true, completion: nil)
            })
            
        } else {
            print("user is already set up, no login process needed")
        }
    }
}

