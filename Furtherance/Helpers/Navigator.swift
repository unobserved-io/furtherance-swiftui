//
//  Navigator.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 26/1/24.
//

import Foundation

enum ViewPath {
    case home
    case reports
    case group
    case settings
}

@Observable
class Navigator {
    static let shared = Navigator()
    
    var path: [ViewPath] = []
    var showTaskBeginsWithHashtagAlert: Bool = false
    
    func openView(_ viewPath: ViewPath) {
        if viewPath == .home {
            path = []
        } else {
            path.append(viewPath)
        }
    }
}
