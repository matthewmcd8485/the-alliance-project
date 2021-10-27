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
    let email = UserDefaults.standard.string(forKey: "email")
    
    let db = Firestore.firestore()
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Edit Picture"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
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
            if let savedImage = ImageStoreManager.shared.retrieveImage(forKey: "profileImage", inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImage.image = savedImage
                }
            }
        }
    }
    
    // MARK: - Saving Image
    @IBAction func saveButton(_ sender: Any) {
        savedLabel.isHidden = true
        savingLabel.isHidden = false
        
        let image = self.profileImage.image
        if let uploadData = UIImage.pngData(image!)() {
            StorageManager.shared.uploadProfilePicture(with: uploadData, fileName: "\(email!) - profile image.png", completion: { [weak self] result in
                
                switch result {
                case .success(let url):
                    self?.db.collection("users").document((self?.email)!).setData([ "Profile Image URL": "\(url)"], merge: true)
                    if let imageToSave = self?.profileImage.image {
                        DispatchQueue.global(qos: .background).async {
                            ImageStoreManager.shared.store(image: imageToSave, forKey: "profileImage", withStorageType: .fileSystem)
                            print("image saved to device!")
                        }
                    }
                    self?.showSavedImageCompletion()
                case .failure(let error):
                    AlertManager.shared.showAlert(title: "Error uploading image", message: "There was an error saving your new image to the database. Please try again. \n \n Error: \(error)")
                    print("Error uploading placeholder profile picture to Firebase: \(error)")
                }
            })
        }
    }
    
    func showSavedImageCompletion() {
        savingLabel.isHidden = true
        savedLabel.isHidden = false
    }
}

