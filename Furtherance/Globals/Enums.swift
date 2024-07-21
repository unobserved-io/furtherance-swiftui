//
//  Enums.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 18/3/24.
//

import Foundation

enum SelectedInspectorView {
    case editTaskGroup
    case editTask
    case addShortcut
    case editShortcut
}

enum NavItems: String, Hashable, CaseIterable {
    case shortcuts
    case timer
    case history
    case report
}
