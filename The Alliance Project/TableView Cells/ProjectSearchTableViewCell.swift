//
//  ProjectSearchTableViewCell.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/8/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ProjectSearchTableViewCell: UITableViewCell {
    static let identifier = "ProjectSearchTableViewCell"
    
    private let projectTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AcherusGrotesque-Bold", size: 20)
        label.textColor = UIColor(named: "purpleColor")
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let categoryDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AcherusGrotesque-Light", size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(projectTitleLabel)
        contentView.addSubview(categoryDateLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        projectTitleLabel.frame = CGRect(x: 10, y: 10, width: contentView.width, height: 40)
        categoryDateLabel.frame = CGRect(x: 10, y: projectTitleLabel.bottom - 10, width: contentView.width, height: 30)
    }
    
    public func configure(with model: Project) {
        // Setting text in labels
        projectTitleLabel.text = model.title
        if model.date == "" {
            categoryDateLabel.text = model.category
        } else if model.category == "" {
            categoryDateLabel.text = "Created on \(model.date)"
        }
    }
}
