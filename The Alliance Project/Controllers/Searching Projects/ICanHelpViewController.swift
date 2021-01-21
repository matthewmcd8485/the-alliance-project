//
//  ICanHelpViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/28/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ICanHelpViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SEARCH PROJECTS"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerData = ["- Pick A Category -", "Application", "Art", "Athletics", "Automotive", "Engineering", "Health & Fitness", "Music", "Photography", "Technology", "Video Creation", "Website Design"]
    }
    
    // MARK: - Picker Delegate
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
    
    // MARK: - Searching
    @IBAction func searchButton(_ sender: Any) {
        if pickerValueSelected == "- Pick A Category -" {
            AlertManager.shared.showAlert(title: "Invalid selection", message: "Please pick a real category.")
        } else {
            performSegue(withIdentifier: "searchSegue", sender: pickerValueSelected)
        }
    }
    
    @IBAction func viewAllButton(_ sender: Any) {
        performSegue(withIdentifier: "searchSegue", sender: "All Projects")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchResultsVC = segue.destination as? SearchResultsViewController, let category = sender as? String {
            searchResultsVC.category = category
        }
    }
    
}
