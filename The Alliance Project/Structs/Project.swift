//
//  Project.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/8/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

struct Project {
    let title: String
    let email: String
    let name: String
    let date: String
    let category: String
    let description: String
    let backgroundImageURL: String
    let backgroundImageCreatorName: String
    let backgroundImageCreatorProfileURL: String
    let projectID: String
    
    init(title: String, email: String, name: String, date: String, category: String, description: String, backgroundImageURL: String, backgroundImageCreatorName: String, backgroundImageCreatorProfileURL: String, projectID: String) {
        self.title = title
        self.email = email
        self.name = name
        self.date = date
        self.category = category
        self.description = description
        self.backgroundImageURL = backgroundImageURL
        self.backgroundImageCreatorName = backgroundImageCreatorName
        self.backgroundImageCreatorProfileURL = backgroundImageCreatorProfileURL
        self.projectID = projectID
    }
    
    public func isBlank() -> Bool {
        if title == "" && email == "" && name == "" && date == "" && category == "" && description == "" && backgroundImageURL == "" && backgroundImageCreatorName == "" && backgroundImageCreatorProfileURL == "" && projectID == "" {
            return true
        }
        return false
    }
}
