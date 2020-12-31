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

class MyAccountViewController: UIViewController, CLLocationManagerDelegate {

    let db = Firestore.firestore()
    
    let fullName = UserDefaults.standard.string(forKey: "fullName")
    let cityAndState = UserDefaults.standard.string(forKey: "cityAndState")
    let email = UserDefaults.standard.string(forKey: "email")
    
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 30
        profileImage.clipsToBounds = true
        
        title = "MY ACCOUNT"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
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
    
    // MARK: - Location Services
    var location: String = ""
    private func setCurrentLocation() {
        locationManager.requestLocation()
        let otherLocationManager = LocationManager()
        guard let exposedLocation = otherLocationManager.exposedLocation else {
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
                self?.cityStateLabel.text = output
                
                guard let userEmail = self?.email else {
                    return
                }
                self?.db.collection("users").document("\(userEmail)").setData(["Locality" : output], merge: true)
                UserDefaults.standard.set("\(output)", forKey: "cityAndState")
            }
        }
    }
    
    func showLocationErrorAlert() {
        let alert = UIAlertController(title: "Error Retrieving Location", message: "There was an error retrieving your current location. Perhaps your location settings are turned off?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Check App Settings", style: .default, handler: {action in
            UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func updateLocationButton(_ sender: Any) {
        let alert = UIAlertController(title: "Update Your Location", message: "You can have the app automatically retrieve your current location, or you can enter your own manually.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Use My Current Location", style: .default, handler: {action in
            self.setCurrentLocation()
        }))
        alert.addAction(UIAlertAction(title: "Enter Custom Location", style: .default, handler: {action in
            self.showCustomLocationField()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCustomLocationField() {
        var textField: UITextField?
        let alertController = UIAlertController(title: "Enter Custom Location", message: "Enter your location in the City, State format.", preferredStyle: .alert)
        let handleAction = UIAlertAction(
        title: "Update", style: .default) {
                (action) -> Void in

                if let location = textField?.text {
                    if location != "" {
                        print("Location = \(location)")
                        self.db.collection("users").document("\(self.email!)").setData(["Locality" : "\(location) (Custom)"], merge: true)
                        UserDefaults.standard.set(location, forKey: "cityAndState")
                        self.cityStateLabel.text = "\(location) (Custom)"
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
        present(alertController, animated: true, completion: nil)
    }
    
    func getInformation() {
        fullNameLabel.text = fullName
    }
    
    func updatePicture() {
        DispatchQueue.global(qos: .background).async {
            if let savedImage = ImageStoreManager.shared.retrieveImage(forKey: "profileImage", inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImage.image = savedImage
                }
            }
        }
    }
    
    func startLocationServices() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()
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
         print("error:: \(error.localizedDescription)")
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


