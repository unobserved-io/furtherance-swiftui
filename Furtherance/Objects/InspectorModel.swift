//
//  InspectorModel.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 09.08.2024.
//

import Foundation

@Observable
class InspectorModel {
	var view: SelectedInspectorView = .editTask
	var show: Bool = false
}

enum SelectedInspectorView {
	case empty
	case editTaskGroup
	case editTask
	case addShortcut
	case editShortcut
}
