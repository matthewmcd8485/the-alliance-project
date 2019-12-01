//
//  PictureEditViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/27/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class PictureEditViewController: UIViewController {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var savedLabel: UILabel!
    @IBOutlet weak var savingLabel: UILabel!
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        savedLabel.isHidden = true
        savingLabel.isHidden = true
        
        updateImageView()
        
        profileImage.layer.cornerRadius = 30
        profileImage.clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView))
        profileImage.addGestureRecognizer(tapGesture)
        profileImage.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        updateImageView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        updateImageView()
    }
    
    func updateImageView() {
        DispatchQueue.global(qos: .background).async {
            if let savedImage = self.retrieveImage(forKey: "profileImage", inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImage.image = savedImage
                }
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        savedLabel.isHidden = true
        savingLabel.isHidden = false
        
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile images").child("\(fullName!) - profile image.png")
        
        if let uploadData = UIImage.pngData(self.profileImage.image!)() {
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                storageRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print("Failed to download url:", error!)
                        return
                    } else {
                        let url = url!
                        self.db.collection("users").document("\(self.fullName!)").setData([ "profile image URL": "\(url)", "UUID": "\(imageName)" ], merge: true)
                        UserDefaults.standard.set("\(imageName)", forKey: "UID")
                        print("image uploaded, user updated!")
                        
                        if let imageToSave = self.profileImage.image {
                            DispatchQueue.global(qos: .background).async {
                                self.store(image: imageToSave, forKey: "profileImage", withStorageType: .fileSystem)
                                print("image saved to device!")
                            }
                        }
                        
                        self.showSavedImageCompletion()
                    }
                    
                })
                
            })
        }
        
    }
    
    func showSavedImageCompletion() {
        savingLabel.isHidden = true
        savedLabel.isHidden = false
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

