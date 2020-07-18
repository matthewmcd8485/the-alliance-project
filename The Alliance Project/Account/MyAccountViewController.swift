//
//  MyAccountViewController.swift
//  The Alliance Project
//
//  Created by Maggie praska on 8/6/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI
import CoreLocation

class MyAccountViewController: UIViewController {

    let db = Firestore.firestore()
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
    let username = UserDefaults.standard.string(forKey: "username")
    
    private let locationManager = LocationManager()
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 30
        profileImage.clipsToBounds = true
        
        getInformation()
        updatePicture()
        
        fullNameLabel.text = fullName
        cityStateLabel.text = cityAndState
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getInformation()
        updatePicture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        getInformation()
        updatePicture()
    }
    
    
    
    func getInformation() {
        fullNameLabel.text = fullName
    }
    
    func updatePicture() {
        DispatchQueue.global(qos: .background).async {
            if let savedImage = self.retrieveImage(forKey: "profileImage", inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImage.image = savedImage
                }
            }
        }
    }
    
    @IBAction func linkInstagram(_ sender: Any) {
        
        showHoldTightAlert()
        
    //    var textField: UITextField?
    //    let alertController = UIAlertController(title: "Add Your Instagram Handle", message: "Link your Instagram profile to your account to show others how cool you are.", preferredStyle: .alert)
    //    let handleAction = UIAlertAction(
    //    title: "Link Instagram", style: .default) {
    //        (action) -> Void in
    //
    //        if let handle = textField?.text {
    //            if textField?.text?.count != 0 {
    //                print("Handle = \(handle)")
    //              UserDefaults.standard.set(handle, forKey: "instagram")
    //                let fullName = UserDefaults.standard.string(forKey: "fullName")
    //                self.db.collection("users").document(fullName!).setData([ "instagram": handle ], merge: true)
    //            } else {
    //                self.showNoUsernameEnteredAlert()
    //            }
    //        }
    //    }
    //    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    //    alertController.addTextField {(handle) -> Void in
    //        textField = handle
    //        textField!.placeholder = "Enter Your Instagram Handle"
    //    }
    //    alertController.addAction(handleAction)
    //    alertController.addAction(cancelAction)
    //    present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func linkTwitter(_ sender: Any) {
        
        showHoldTightAlert()
        
    }
    
    @IBAction func linkYouTube(_ sender: Any) {
        
        showHoldTightAlert()
        
    }
    
    @IBAction func linkWebsite(_ sender: Any) {
        
        showHoldTightAlert()
        
    }
    
    func showNoUsernameEnteredAlert() {
        print("No Username entered")
        let nothingEnteredAlertController = UIAlertController(title: "Nothing Entered", message: "Nothing was entered in the text field. Please enter your handle.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        nothingEnteredAlertController.addAction(okAction)
        self.present(nothingEnteredAlertController, animated: true, completion: nil)
    }
    
    func generateField(applicationType: String) -> String {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Add Your \(applicationType)", message: "Add your social media accounts to help others verify your skills.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Link", style: .default) {
            (action) -> Void in

            if let handle = textField?.text {
                print("Handle = \(handle)")
            } else {
                print("No Username entered")
            }
        }
        alertController.addTextField {(handle) -> Void in
            textField = handle
            textField!.placeholder = "Enter Your \(applicationType)"
        }
        alertController.addAction(handleAction)
        present(alertController, animated: true, completion: nil)
        
        return textField?.text ?? ""
    }
    
    func showHoldTightAlert() {
        let alert = UIAlertController(title: "Hold Tight!", message: "The action you are attempting is not quite ready yet. Check back in future beta updates for proper functionality.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    enum StorageType {
        case userDefaults
        case fileSystem
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    private func store(image: UIImage, forKey key: String, withStorageType storageType: StorageType) {
        if let pngRepresentation = image.pngData() {
            switch storageType {
            case .fileSystem:
                if let filePath = filePath(forKey: key) {
                    do  {
                        try pngRepresentation.write(to: filePath,
                                                    options: .atomic)
                    } catch let err {
                        print("Saving file resulted in error: ", err)
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation, forKey: key)
            }
        }
    }
    
    private func retrieveImage(forKey key: String, inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
                let fileData = FileManager.default.contents(atPath: filePath.path),
                let image = UIImage(data: fileData) {
                return image
            }
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
}


