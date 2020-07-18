//
//  SpecificsViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class SpecificsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let db = Firestore.firestore()

    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerData = ["Pick A Category", "Application", "Art", "Athletics", "Music", "Photography", "Technology", "Video Creation", "Website Design"]
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            var label = UILabel()
            if let v = view {
                label = v as! UILabel
            }
            label.font = UIFont (name: "AcherusGrotesque-Light", size: 17)
            label.text =  pickerData[row]
            label.textAlignment = .center
            return label
        }
    
    var pickerValueSelected: String = ""
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerValueSelected = pickerData[row] as String
    }
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    let username = UserDefaults.standard.string(forKey: "username")
    let projectTitle = UserDefaults.standard.string(forKey: "projectTitle")
    let projectDescription = UserDefaults.standard.string(forKey: "projectDescription")
    let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
    let email = UserDefaults.standard.string(forKey: "email")
    
    @IBAction func createButton(_ sender: Any) {
        let today = Date()
        db.collection("users").document("\(username!)").collection("projects").document("\(projectTitle!)").setData([
            
            "Project Title": projectTitle!,
            "Project Description": projectDescription!,
            "Category": pickerValueSelected,
            "Date Created": today.toString(dateFormat: "MMM dd, YYYY"),
            "Views": 0,
            "Creator Name": fullName!,
            "Creator Username": username!,
            "Locality": cityAndState!,
            "Creator Email": email!
            
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
                
                let alert = UIAlertController(title: "Error creating account", message: "There was an error when creating the project. Please try again.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Project successfully created!")
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "myProjectsVC")
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

}
