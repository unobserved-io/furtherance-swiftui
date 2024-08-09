//
//  Enums.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 18/3/24.
//

import Foundation

enum SelectedInspectorView {
    case empty
    case editTaskGroup
    case editTask
    case addShortcut
    case editShortcut
}

enum NavItems: String, Hashable, CaseIterable, Identifiable {
    case shortcuts
    case timer
    case history
    case report
	case buyPro

    var id: Self { self }
}
