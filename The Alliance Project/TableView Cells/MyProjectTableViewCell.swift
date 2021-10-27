//
//  MyProjectTableViewCell.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/29/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class MyProjectTableViewCell: UITableViewCell {
    static let identifier = "MyProjectTableViewCell"
    
    private let projectTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AcherusGrotesque-Bold", size: 30)
        label.textColor = UIColor(named: "purpleColor")
        label.numberOfLines = 0
        label.textAlignment = .left
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
    
    private let backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0
        return backgroundImageView
    }()
    
    private let backgroundDimView: UIView = {
        let backgroundDimView = UIView()
        backgroundDimView.backgroundColor = .black
        backgroundDimView.alpha = 0
        return backgroundDimView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(backgroundDimView)
        contentView.addSubview(projectTitleLabel)
        contentView.addSubview(categoryDateLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: contentView.width, height: 150)
        backgroundDimView.frame = CGRect(x: 0, y: 0, width: contentView.width, height: 150)
        projectTitleLabel.frame = CGRect(x: 10, y: 10, width: contentView.width, height: 50)
        categoryDateLabel.frame = CGRect(x: 10, y: projectTitleLabel.bottom, width: contentView.width, height: 30)
    }
    
    public func configure(with model: Project) {
        // Setting text in labels and image in background
        projectTitleLabel.text = model.title
        categoryDateLabel.text = "\(model.category), created on \(model.date)"
    }
    
}
