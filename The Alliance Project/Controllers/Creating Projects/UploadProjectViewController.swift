//
//  SuccessViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/25/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class SuccessViewController: UIViewController {

    @IBOutlet weak var checkmarkView: UIImageView!
    
    let shape = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "New Project"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let circlePath = UIBezierPath(arcCenter: checkmarkView.center, radius: 120, startAngle: -(.pi / 2), endAngle: 3 * (.pi / 2), clockwise: true)
        circlePath.lineCapStyle = .round
        
        shape.path = circlePath.cgPath
        shape.lineWidth = 15
        shape.lineCap = .round
        shape.strokeColor = UIColor.systemGreen.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeEnd = 0
        view.layer.addSublayer(shape)
        
        animate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func animate() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.toValue = 1
        animation.duration = 1
        animation.timingFunction = timingFunction
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            self.shape.add(animation, forKey: "animation")
        })
    }

    @IBAction func doneButton(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
