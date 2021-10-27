//
//  Location.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/26/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MessageKit

struct Location: LocationItem {
    let location: CLLocation
    let size: CGSize
}
