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
import FirebaseAuthUI
import CoreLocation

class MyAccountViewController: UIViewController, CLLocationManagerDelegate {

    let db = Firestore.firestore()
    let databaseManager = DatabaseManager.shared
    let alertManager = AlertManager.shared
    let profanityManager = ProfanityManager.shared
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
    let email = UserDefaults.standard.string(forKey: "email")
    
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundDimView: UIView!
    @IBOutlet weak var customizationsLabel: UILabel!
    @IBOutlet weak var updateLocationLabel: UILabel!
    @IBOutlet weak var backgroundImageLabel: UILabel!
    @IBOutlet weak var profileImageLabel: UILabel!
    @IBOutlet weak var linkAccountsLabel: UILabel!
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 30
        profileImage.clipsToBounds = true
        profileImage.alpha = 0
        
        navigationItem.title = "My Profile"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        button.tintColor = UIColor(named: "purpleColor")
        button.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        backgroundDimView.alpha = 0
        backgroundImageView.alpha = 0
        
        getInformation()
        updatePictures()
        
        fullNameLabel.text = "Hi, I'm \(fullName!)"
        cityStateLabel.text = "I'm from \(cityAndState!)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.backItem?.backBarButtonItem?.tintColor = UIColor(named: "purpleColor")
        navigationController?.navigationBar.backItem?.backButtonTitle = ""
    }
    
    @objc private func didTapSettingsButton() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "settingsVC") as? SettingsViewController else {
                return
            }
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    // MARK: - Updating Images
    private func updatePictures() {
        DispatchQueue.global(qos: .background).async {
            if let savedImage = ImageStoreManager.shared.retrieveImage(forKey: "profileImage", inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImage.image = savedImage
                    UIView.animate(withDuration: 0.5) {
                        self.profileImage.alpha = 1
                    }
                }
            }
            if let backgroundImageInfo = UserDefaults.standard.stringArray(forKey: "profileBackgroundImageArray") {
                if backgroundImageInfo[0] != "" {
                    self.configureBackgroundImage(with: backgroundImageInfo[0])
                }
            }
        }
    }
    
    @IBAction func updateBackgroundImage(_ sender: Any) {
        
        // Load the image if one is cached, do nothing otherwise
        if let backgroundInfo = UserDefaults.standard.stringArray(forKey: "profileBackgroundImageArray"), backgroundInfo[0] != "" {
            let name = backgroundInfo[1]
            let link = backgroundInfo[2]
            let actionSheet = UIAlertController(title: "Background image options", message: "You can view \(name)'s profile on Unsplash or pick a new photo from the Unsplash library.", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "View \(name) on Unsplash", style: .default, handler: { action in
                if let path = URL(string: link) {
                        UIApplication.shared.open(path, options: [:], completionHandler: nil)
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Choose a new background image", style: .default, handler: { [weak self] action in
                self?.selectNewBackgroundImage()
            }))
            actionSheet.addAction(UIAlertAction(title: "Delete background image", style: .destructive, handler: { [weak self] action in
                self?.removeBackgroundImage()
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(actionSheet, animated: true, completion: nil)
        } else {
            selectNewBackgroundImage()
        }
    }
    
    // MARK: - New Background Image
    private func selectNewBackgroundImage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "backgroundImageVC") as BackgroundImageViewController
        rvc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            guard result.id != "" else {
                return
            }
            
            strongSelf.photoResult = [result.urls.full, result.user.name, result.user.links.html]
            
            UserDefaults.standard.set(strongSelf.photoResult, forKey: "profileBackgroundImageArray")
            
            strongSelf.db.collection("users").document(strongSelf.email!).setData([
                "Profile Background Image URL" : result.urls.full,
                "Profile Background Image Creator Name" : result.user.name,
                "Profile Background Image Creator Profile Link" : result.user.links.html
            ], merge: true, completion: { error in
                guard error == nil else {
                    print("Error uploading background image info: \(error!)")
                    return
                }
                print("Background image uploaded!")
                strongSelf.configureBackgroundImage(with: result.urls.full)
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Remove Background Image
    private func removeBackgroundImage() {
        db.collection("users").document(email!).setData([
            "Profile Background Image Creator Name" : "",
            "Profile Background Image Creator Profile Link" : "",
            "Profile Background Image URL" : ""
        ], merge: true, completion: { [weak self] error in
            guard error == nil else {
                print("Error removing profile background image from Firestore: \(error!)")
                return
            }
            
            // Remove the image from device cache
            UserDefaults.standard.set(["", "", ""], forKey: "profileBackgroundImageArray")
            
            // Update the UI
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5) {
                    self?.backgroundDimView.alpha = 0
                    self?.backgroundImageView.alpha = 0
                    self?.fullNameLabel.textColor = .label
                    self?.cityStateLabel.textColor = .label
                    self?.customizationsLabel.textColor = .label
                    self?.backgroundImageLabel.textColor = .lightGray
                    self?.profileImageLabel.textColor = .lightGray
                    self?.linkAccountsLabel.textColor = .lightGray
                    self?.updateLocationLabel.textColor = .lightGray
                }
                
                self?.backgroundImageView.image = nil
            }
            
            print("Profile background image successfully removed!")
        })
    }
    
    // MARK: - Configure Background
    private func configureBackgroundImage(with urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        let token = "dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self?.backgroundImageView.image = image
                
                UIView.animate(withDuration: 0.5) {
                    self?.backgroundDimView.alpha = 1
                    self?.backgroundImageView.alpha = 1
                    self?.fullNameLabel.textColor = .white
                    self?.cityStateLabel.textColor = .white
                    self?.customizationsLabel.textColor = .white
                    self?.backgroundImageLabel.textColor = .white
                    self?.profileImageLabel.textColor = .white
                    self?.linkAccountsLabel.textColor = .white
                    self?.updateLocationLabel.textColor = .white
                }
                
            }
        }.resume()
    }
    
    var photoResult: [String] = [""]
    
    // MARK: - Location Services
    var location: String = ""
    private func setCurrentLocation() {
        locationManager.requestLocation()
        let otherLocationManager = LocationManager()
        guard let exposedLocation = otherLocationManager.exposedLocation else {
            showLocationErrorAlert()
            print("*** Error in \(#function): exposedLocation is nil")
            return
        }
        
        if currentLocation != nil {
            otherLocationManager.getPlace(for: exposedLocation) { [weak self] placemark in
                guard let placemark = placemark else { return }
                
                var output = ""
                
                if let city = placemark.locality {
                    output = output + "\(city)"
                }
                if let state = placemark.administrativeArea {
                    output = output + ", \(state)"
                }
                self?.cityStateLabel.text = "I'm from \(output)"
                
                guard let userEmail = self?.email else {
                    return
                }
                self?.databaseManager.updateField(for: userEmail, fieldToUpdate: "Locality", valueToSave: output, merge: true, completion: { success in
                    if success {
                        UserDefaults.standard.set("\(output)", forKey: "cityAndState")
                    } else {
                        self?.showLocationErrorAlert()
                    }
                })
                
            }
        }
    }
    
    private func showLocationErrorAlert() {
        if !UserDefaults.standard.bool(forKey: "locationErrorDismissal") {
            let alert = UIAlertController(title: "Error retrieving location", message: "There was an error retrieving your current location. Perhaps your location settings are turned off?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Check app settings", style: .default, handler: { action in
                UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }))
            alert.addAction(UIAlertAction(title: "Don't show again", style: .destructive, handler: { action in
                UserDefaults.standard.set(true, forKey: "locationErrorDismissal")
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Update Location
    @IBAction func updateLocationButton(_ sender: Any) {
        let alert = UIAlertController(title: "Update your location", message: "You can have the app automatically retrieve your current location, or you can enter your own manually.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Use my current location", style: .default, handler: {action in
            self.setCurrentLocation()
        }))
        alert.addAction(UIAlertAction(title: "Enter custom location", style: .default, handler: {action in
            self.showCustomLocationField()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showCustomLocationField() {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Enter custom location", message: "Enter your location in the City, State format.", preferredStyle: .alert)
        let handleAction = UIAlertAction(title: "Update", style: .default) { (action) -> Void in
                if let location = textField?.text {
                    
                    // Check for profanity in the custom location
                    if self.profanityManager.checkForProfanity(in: location) {
                        self.alertManager.showAlert(title: "Inappropriate language", message: "There are some less-than-ideal words in your custom location. Please name a real place. Nice try, though.")
                    } else {
                        if location != "" {
                            print("Location = \(location)")
                            self.db.collection("users").document("\(self.email!)").setData(["Locality" : "\(location) (custom)"], merge: true)
                            UserDefaults.standard.set("\(location) (custom)", forKey: "cityAndState")
                            self.cityStateLabel.text = "I'm from \(location) (custom)"
                        }
                    }
                } else {
                    print("No location entered")
                }
            }
        alertController.addTextField {(location) -> Void in
            textField = location
            textField!.placeholder = "Example: Chicago, IL"
        }
        alertController.addAction(handleAction)
        alertController.addAction((UIAlertAction(title: "Cancel", style: .cancel, handler: nil)))
        present(alertController, animated: true, completion: nil)
    }
    
    private func getInformation() {
        fullNameLabel.text = fullName
    }
    
    private func startLocationServices() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let locationAuthorizationStatus = locationManager.authorizationStatus // MIGHT THROW ERROR
        switch locationAuthorizationStatus {
        case .notDetermined: self.locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
            }
        case .restricted, .denied: break
        @unknown default:
            fatalError()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location failure error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined: break
        case .authorizedWhenInUse, .authorizedAlways: if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
            }
        case .restricted, .denied: break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.first
    }

}


