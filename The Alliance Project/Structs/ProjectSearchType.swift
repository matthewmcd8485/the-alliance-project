//
//  ProjectSearchType.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/14/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import Foundation

struct ProjectSearchType {
    let category: String?
    let searchForAll: Bool?
    let keyword: String?
    
    init(category: String) {
        self.category = category
        self.searchForAll = nil
        self.keyword = nil
    }
    
    init(searchForAll: Bool) {
        self.category = nil
        self.searchForAll = searchForAll
        self.keyword = nil
    }
    
    init(keyword: String) {
        self.category = nil
        self.searchForAll = nil
        self.keyword = keyword
    }
}
