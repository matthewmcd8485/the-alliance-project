//
//  SecondOnboardingViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 7/11/19.
//  Copyright © 2019 Matthew McDonnell. All rights reserved.
//

import UIKit
import CoreLocation

class SecondOnboardingViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var privacyTitle: UILabel!
    @IBOutlet var privacyDetail: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var deviceLabel: UILabel!
    @IBOutlet var buttonLabel: UIButton!
    @IBOutlet var privacyButtonLabel: UIButton!
    
    @IBAction func privacyButton(_ sender: Any) {
        guard let url = URL(string: "https://matthewdevteam.weebly.com/privacy.html") else { return }
        UIApplication.shared.open(url)
    }
    
    
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    
    @IBAction func askForLocationAccess(_ sender: Any) {

        locationManager.delegate = self
        self.startLocationServices()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.userInterfaceStyle == .light {
            buttonLabel.tintColor = .black
        } else {
            buttonLabel.tintColor = .white
        }
        
        privacyButtonLabel.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.userInterfaceStyle == .light {
            buttonLabel.tintColor = .black
        } else {
            buttonLabel.tintColor = .white
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
        case .restricted, .denied: self.alertLocationAccessNeeded()
        @unknown default:
            fatalError()
        }
    }
    
    func alertLocationAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(title: "Setup Location Access Later", message: "Location access is not required, but you should manually enter it to give you access to collaborators nearest you.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Setup Later", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow Location Access", style: .cancel, handler: { (alert) -> Void in UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)}))
        
        present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined: break
        case .authorizedWhenInUse, .authorizedAlways: if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
            }
        case .restricted, .denied: self.alertLocationAccessNeeded()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last
    }
}
