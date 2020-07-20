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


