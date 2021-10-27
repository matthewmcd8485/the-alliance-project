//
//  FIOAuth.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuthUI
import AuthenticationServices

extension FUIOAuth {
    static func swizzleAppleAuthCompletion() {
        let instance = FUIOAuth.appleAuthProvider()
        let originalSelector = NSSelectorFromString("authorizationController:didCompleteWithAuthorization:")
        let swizzledSelector = #selector(swizzledAuthorizationController(controller:didCompleteWithAuthorization:))
        guard let originalMethod = class_getInstanceMethod(instance.classForCoder, originalSelector),
              let swizzledMethod = class_getInstanceMethod(instance.classForCoder, swizzledSelector) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc func swizzledAuthorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let nameComponents = (authorization.credential as? ASAuthorizationAppleIDCredential)?.fullName {
            let nameFormatter = PersonNameComponentsFormatter()
            let displayName = nameFormatter.string(from: nameComponents)
            UserDefaults.standard.setValue(displayName, forKey: "displayName")
            UserDefaults.standard.synchronize()
        }
        swizzledAuthorizationController(controller: controller, didCompleteWithAuthorization: authorization)
    }
}
