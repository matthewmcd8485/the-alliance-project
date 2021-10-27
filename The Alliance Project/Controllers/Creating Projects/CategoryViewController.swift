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

class CategoryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    public var completion: ((String) -> (Void))?
    let db = Firestore.firestore()
    let alertManager = AlertManager.shared
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Project"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerData = PickerData.pickerData
    }
    
    // MARK: - Picker Delegates
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
    
    var pickerValueSelected: String = "- Pick A Category -"
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerValueSelected = pickerData[row] as String
    }
    
    // MARK: - Create Project
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    let projectTitle = UserDefaults.standard.string(forKey: "projectTitle")
    let projectDescription = UserDefaults.standard.string(forKey: "projectDescription")
    let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
    let email = UserDefaults.standard.string(forKey: "email")
    let fcmToken = UserDefaults.standard.string(forKey: "fcmToken")
    
    @IBAction func createButton(_ sender: Any) {
        if pickerValueSelected == "- Pick A Category -" {
            alertManager.showAlert(title: "Invalid selection", message: "Please pick a real category.")
        } else {
            completion!(pickerValueSelected)
            self.navigationController?.popViewController(animated: true)
        }
    }
}
