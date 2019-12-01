//
//  firstOnboardingViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/10/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit

class onboardingNavigationController: UINavigationController {
    
}

class firstOnboardingViewController: UIViewController {

    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var peerLabel: UILabel!
    @IBOutlet var getStartedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.userInterfaceStyle == .light {
            getStartedButton.tintColor = .black
        } else {
            getStartedButton.tintColor = .white
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.userInterfaceStyle == .light {
            getStartedButton.tintColor = .black
        } else {
            getStartedButton.tintColor = .white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
