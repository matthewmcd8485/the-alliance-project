//
//  BackgroundGradient.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 2/6/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class BackgroundGradient {
    var gradientLayer : CAGradientLayer!

    init() {
        let colorTop = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        let colorBottom = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1).cgColor

        self.gradientLayer = CAGradientLayer()
        self.gradientLayer.colors = [colorTop, colorBottom]
        self.gradientLayer.locations = [0.0, 1.0]
    }
}
