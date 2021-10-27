//
//  UIView.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/25/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit

// For formatting subviews inside of a UIView
extension UIView {
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var bottom: CGFloat {
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.size.width + frame.origin.x
    }
}

// For adding background images to UIViews
extension UIView {
    func addBackground(with urlString: String) {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
       
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageViewBackground.contentMode = .scaleAspectFill
        imageViewBackground.alpha = 0
        
        self.addSubview(imageViewBackground)
        self.sendSubviewToBack(imageViewBackground)
       
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageViewBackground.image = image
                
                UIView.animate(withDuration: 0.5) {
                    imageViewBackground.alpha = 1
                }
            }
        }.resume()
    }
}

