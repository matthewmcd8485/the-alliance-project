//
//  AboutThisAppViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/14/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit

class AboutThisAppViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ABOUT"
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
    }
    
    @IBAction func writeReviewButton(_ sender: Any) {
        let appleID = "1472305440"
        let url = "https://itunes.apple.com/app/id\(appleID)?action=write-review"
        if let path = URL(string: url) {
                UIApplication.shared.open(path, options: [:], completionHandler: nil)
        }
    }
}
