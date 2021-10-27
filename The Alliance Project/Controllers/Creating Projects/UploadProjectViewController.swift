//
//  SuccessViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/25/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class UploadProjectViewController: UIViewController {

    @IBOutlet weak var checkmarkView: UIImageView!
    @IBOutlet weak var doneButtonLayer: UIButton!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let shape = CAShapeLayer()
    
    let db = Firestore.firestore()
    let alertManager = AlertManager.shared
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "New Project"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        checkmarkView.alpha = 0
        doneButtonLayer.alpha = 0
        doneButtonLayer.isEnabled = false
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let circlePath = UIBezierPath(arcCenter: checkmarkView.center, radius: 120, startAngle: -(.pi / 2), endAngle: 3 * (.pi / 2), clockwise: true)
        circlePath.lineCapStyle = .round
        
        shape.path = circlePath.cgPath
        shape.lineWidth = 15
        shape.lineCap = .round
        shape.strokeColor = UIColor.systemGreen.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeEnd = 0
        view.layer.addSublayer(shape)
        
        
        uploadProject()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animate()
    }
    
    // MARK: - Upload Project
    private func uploadProject() {
        var photoCreatorName = ""
        var photoCreatorURL = ""
        var projectBackgroundImageURL = ""
        
        let today = Date()
        let projectTitle = UserDefaults.standard.string(forKey: "projectTitle")
        let projectDescription = UserDefaults.standard.string(forKey: "projectDescription")
       // let projectBackgroundImageURL = UserDefaults.standard.string(forKey: "projectBackgroundImageURL")
        let projectCategory = UserDefaults.standard.string(forKey: "projectCategory")
        let fullName = UserDefaults.standard.string(forKey: "fullName")
        let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
        let fcmToken = UserDefaults.standard.string(forKey: "fcmToken")
        let email = UserDefaults.standard.string(forKey: "email")
        
        let photoResult = UserDefaults.standard.stringArray(forKey: "photoResult")!
        if photoResult[2] != "" {
            photoCreatorURL = photoResult[2]
            photoCreatorName = photoResult[1]
            projectBackgroundImageURL = photoResult[0]
        }

        db.collection("users").document("\(email!)").collection("projects").document("\(projectTitle!)").setData([
        
            "Project Title": projectTitle!,
            "Project Description": projectDescription!,
            "Category": projectCategory!,
            "Date Created": today.toString(dateFormat: "MMM dd, YYYY"),
            "Views": 0,
            "Creator Name": fullName!,
            "Locality": cityAndState!,
            "Creator Email": email!,
            "Creator FCM Token" : fcmToken ?? "",
            "Background Image URL" : projectBackgroundImageURL,
            "Background Image Creator Name" : photoCreatorName,
            "Background Image Creator Profile URL" : photoCreatorURL,
            "Project ID" : UUID().uuidString
        
        ]) { [weak self] err in
            if let err = err {
                print("Error creating project: \(err)")
        
                self?.alertManager.showAlert(title: "Error creating project", message: "There was an error when creating the project. Please try again.")
            } else {
                print("Project successfully created!")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    self?.doneButtonLayer.isEnabled = true
                    self?.uploadingLabel.text = "SUCCESS!"
                    self?.descriptionLabel.text = "Your project has been successfully created"
                    
                    UIView.animate(withDuration: 0.5) {
                            self?.checkmarkView.alpha = 1.0
                            self?.doneButtonLayer.alpha = 1.0
                        }
                })
            }
        }
    }
    
    private func animate() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.toValue = 1
        animation.duration = 1.5
        animation.timingFunction = timingFunction
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.shape.add(animation, forKey: "animation")
            self.doneButtonLayer.isEnabled = true
        })
    }

    @IBAction func doneButton(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
