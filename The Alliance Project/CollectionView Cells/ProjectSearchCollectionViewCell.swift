//
//  ProjectSearchCollectionViewCell.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/14/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class ProjectSearchCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProjectSearchCollectionViewCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    private let categoryLabel: UILabel = {
        let categoryLabel = UILabel()
        categoryLabel.text = ""
        categoryLabel.font = UIFont(name: "AcherusGrotesque-Bold", size: 20)!
        categoryLabel.textAlignment = .center
        categoryLabel.textColor = .white
        return categoryLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(categoryLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
        categoryLabel.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        categoryLabel.text = ""
    }
    
    func configure(with image: UIImage, category: String) {
        //imageView.image = image
        categoryLabel.text = category
        layer.backgroundColor = UIColor.black.cgColor
        imageView.image = image
        imageView.alpha = 0.4
    }
}
