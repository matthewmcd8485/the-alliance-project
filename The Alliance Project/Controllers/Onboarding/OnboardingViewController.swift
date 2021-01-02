//
//  firstOnboardingViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/10/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseRemoteConfig
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI
import GoogleSignIn
import AuthenticationServices

class OnboardingViewController: UIViewController, CLLocationManagerDelegate, FUIAuthDelegate {
    
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var peerLabel: UILabel!
    @IBOutlet var getStartedButton: UIButton!
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let remoteConfig = RemoteConfig.remoteConfig()
    let alertManager = AlertManager.shared
    
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    var blacklistedUsers: [String : NSObject] = ["blacklisted_users" : "" as NSObject]
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getStartedButton.layer.cornerRadius = 10
        
        setupRemoteConfigDefaults()
        fetchRemoteConfigValues()
        
        if traitCollection.userInterfaceStyle == .light {
            getStartedButton.tintColor = .black
        } else {
            getStartedButton.tintColor = .white
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.userInterfaceStyle == .light {
            getStartedButton.tintColor = .black
        } else {
            getStartedButton.tintColor = .white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupRemoteConfigDefaults() {
        let defaultValues = ["blacklisted_users" : "" as NSObject]
        
        remoteConfig.setDefaults(defaultValues)
        blacklistedUsers = defaultValues
    }
    
    private func fetchRemoteConfigValues() {
        remoteConfig.fetchAndActivate() { status, error in
            guard error == nil else {
                print("Error reaching Firebse Remote Config: \(error!)")
                return
            }
        }
    }
    
    // MARK: - Signing In
    @IBAction func signInButton(_ sender: Any) {
        locationManager.delegate = self
        startLocationServices()
        
        let termsAlert = UIAlertController(title: "Agree before continuing", message: "By using The Alliance Project, you agree to abide by the standards of user content and safety outlined in the Privacy Policy and Terms of Service. \n \n These terms can also be found in the Settings page at any time.", preferredStyle: .alert)
        termsAlert.addAction(UIAlertAction(title: "View Terms of Service", style: .default, handler: { action in
            // Open terms of service
            
            guard let url = URL(string: "https://matthewdevteam.weebly.com/terms-and-conditions.html") else { return }
            UIApplication.shared.open(url)
        }))
        termsAlert.addAction(UIAlertAction(title: "View Privacy Policy", style: .default, handler: { action in
            // Open privacy policy
            
            guard let url = URL(string: "https://matthewdevteam.weebly.com/privacy.html") else { return }
            UIApplication.shared.open(url)
        }))
        termsAlert.addAction(UIAlertAction(title: "I disagree", style: .destructive, handler: { action in
            // Do nothing
        }))
        termsAlert.addAction(UIAlertAction(title: "I agree", style: .cancel, handler: { [weak self] action in
            // Continue with sign-in flow
            
            // blacklistedUsers = ["blacklisted_users" : remoteConfig.value(forKey: "blacklisted_users") as! NSObject]
            // print(blacklistedUsers)
            
            if let authUI = FUIAuth.defaultAuthUI() {
                authUI.privacyPolicyURL = URL(string: "https://matthewdevteam.weebly.com/privacy.html")!
                authUI.tosurl = URL(string: "https://matthewdevteam.weebly.com/terms-and-conditions.html")!
                authUI.providers = [FUIOAuth.appleAuthProvider(), FUIGoogleAuth(), FUIEmailAuth()]
                FUIOAuth.swizzleAppleAuthCompletion()
                authUI.delegate = self
                
                let authViewController = authUI.authViewController()
                self?.present(authViewController, animated: true)
                
                Auth.auth().addStateDidChangeListener { (auth, user) in
                    guard let user = user,
                          user.displayName == nil,
                          let displayName = UserDefaults.standard.string(forKey: "displayName") else { return }
                    
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges(completion: { (_) in
                        UserDefaults.standard.setValue(nil, forKey: "displayName")
                        UserDefaults.standard.synchronize()
                    })
                }
            }
        }))
        present(termsAlert, animated: true, completion: nil)
    }
    
    var firstName: String = ""
    var lastName: String = ""
    var fullName: String = ""
    var email: String = ""
    var profileImageURL: String = ""
    
    func createSpinnerView() {
        let child = SpinnerViewController()
        
        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
        
        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    // MARK: - FirebaseUI Auth
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if error != nil {
            // The most common error occurs when users cancel the sign-in flow, so I got rid of the error AlertController.
            print(error!)
        } else if let user = authDataResult?.user {
            if authDataResult!.additionalUserInfo!.isNewUser {
                print("This is a new user! email: \(user.email ?? "[NO EMAIL]"), name: \(authDataResult?.user.displayName ?? "[NO NAME]"), uid: \(user.uid)")
                
                setCurrentLocation()
                
                // Upload placeholder profile image to Firebase Storage
                let image = UIImage(named: "placeholder.png")
                if let uploadData = UIImage.pngData(image!)() {
                    StorageManager.shared.uploadProfilePicture(with: uploadData, fileName: "\(user.email!) - profile image.png", completion: { [weak self] result in
                        
                        guard let strongSelf = self else {
                            return
                        }
                        switch result {
                        
                        // Profile image upload succeded
                        case .success(let url):
                            strongSelf.profileImageURL = url
                            DispatchQueue.global(qos: .background).async {
                                ImageStoreManager.shared.store(image: image!, forKey: "profileImage", withStorageType: .fileSystem)
                                print("image saved to device!")
                            }
                            
                            guard var nameToCommit = authDataResult?.user.displayName else {
                                print("User display name is nil")
                                return
                            }
                            if nameToCommit == "" {
                                nameToCommit = "user-\(user.uid)"
                            }
                            
                            // Finish creating Firestore user
                            strongSelf.db.collection("users").document(user.email!).setData([
                                "User Identifier" : user.uid,
                                "Email Address" : user.email!,
                                "Full Name" : nameToCommit,
                                "Locality" : strongSelf.location,
                                "Profile Image URL" : strongSelf.profileImageURL,
                                "Instagram" : "",
                                "Twitter" : "",
                                "YouTube" : "",
                                "Website" : "",
                                "Firebase Cloud Messaging Token" : "Notifications not set up yet"
                            ], merge: true, completion: { error in
                                guard error == nil else {
                                    print("Error creating user in Firestore: \(error!)")
                                    return
                                }
                                UserDefaults.standard.set(strongSelf.location, forKey: "cityAndState")
                                UserDefaults.standard.set(user.email!, forKey: "email")
                                UserDefaults.standard.set(nameToCommit, forKey: "fullName")
                                UserDefaults.standard.set(user.uid, forKey: "userIdentifier")
                                UserDefaults.standard.set(true, forKey: "loggedIn")
                                UserDefaults.standard.set(false, forKey: "locationErrorDismissal")
                                UserDefaults.standard.set([""], forKey: "blockedUsers")
                                
                                DispatchQueue.main.async {
                                    Messaging.messaging().subscribe(toTopic: "All users") { error in
                                        print("Subscribed to notification topic: All users")
                                    }
                                    strongSelf.navigationController?.popViewController(animated: true)
                                }
                            })
                        // Profile Image Upload Failed
                        case .failure(let error):
                            self?.profileImageURL = "No profile picture yet"
                            print("Error uploading placeholder profile picture to Firebase: \(error)")
                        }
                    })
                }
            } else {
                print("This is a returning user! uid: \(user.uid)")
                
                db.collection("users").whereField("User Identifier", isEqualTo: user.uid).getDocuments() { [weak self] QuerySnapshot, error in
                    guard let strongSelf = self else {
                        return
                    }
                    if error != nil {
                        strongSelf.alertManager.showAlert(title: "Error logging in", message: "There was an error signing into your account. Please try again. \n \n Error: \(error!)")
                    } else {
                        for document in QuerySnapshot!.documents {
                            let email = document.get("Email Address")
                            let fullName = document.get("Full Name")
                            let locality = document.get("Locality")
                            let instagram = document.get("Instagram")
                            let twitter = document.get("Twitter")
                            let youtube = document.get("YouTube")
                            let website = document.get("Website")
                            let profileImageURL: String = document.get("Profile Image URL") as! String
                            
                            if profileImageURL != "No profile picture yet" {
                                let storageRef = Storage.storage().reference(withPath: "profile images/\(email!) - profile image.png")
                                storageRef.getData(maxSize: 2 * 2048 * 2048) { data, error in
                                    if let error = error {
                                        print(error)
                                    } else {
                                        // Data for profile image is returned
                                        print("data = \(data!)")
                                        let imageToSave = UIImage(data: data!)
                                        ImageStoreManager.shared.store(image: imageToSave!, forKey: "profileImage", withStorageType: .fileSystem)
                                    }
                                }
                            }
                            
                            UserDefaults.standard.setValue(instagram, forKey: "instagram")
                            UserDefaults.standard.setValue(twitter, forKey: "twitter")
                            UserDefaults.standard.setValue(youtube, forKey: "youtube")
                            UserDefaults.standard.setValue(website, forKey: "website")
                            UserDefaults.standard.set(email, forKey: "email")
                            UserDefaults.standard.set(fullName, forKey: "fullName")
                            UserDefaults.standard.set(locality, forKey: "cityAndState")
                            UserDefaults.standard.set(user.uid, forKey: "userIdentifier")
                            UserDefaults.standard.set([""], forKey: "blockedUsers")
                            UserDefaults.standard.set(false, forKey: "locationErrorDismissal")
                        }
                        
                        // Update the list of blocked users
                        DatabaseManager.shared.updateBlockedUsersList(for: strongSelf.email, completion: { success in
                            if success {
                                print("Successfully updated list of blocked users")
                            }
                        })
                        
                        UserDefaults.standard.set(true, forKey: "loggedIn")
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Location Services
    var location: String = ""
    private func setCurrentLocation() {
        locationManager.requestLocation()
        let otherLocationManager = LocationManager()
        guard let exposedLocation = otherLocationManager.exposedLocation else {
            location = "Location not set"
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
                self?.location = output
                
            }
        }
    }
    
    private func startLocationServices() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()
        switch locationAuthorizationStatus {
        case .notDetermined: self.locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
        case .restricted, .denied:
            break
        @unknown default:
            fatalError()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined: break
        case .authorizedWhenInUse, .authorizedAlways: if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }
    
    private func alertLocationAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(title: "Setup location access", message: "Although location access is not required, it can give you access to collaborators nearest you.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Setup later", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow location access", style: .cancel, handler: { (alert) -> Void in UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)}))
        
        present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Gets called if the app tries to grab a location without necessary permissions
        print("location failure error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}


