//
//  BackBarButtonItem.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 12/3/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit

class BackBarButtonItem: UIBarButtonItem {
    @available(iOS 14.0, *)
    override var menu: UIMenu? {
        set {
            /* Don't set the menu here */
            /* super.menu = menu */
        }
        get {
            return super.menu
        }
    }
}
