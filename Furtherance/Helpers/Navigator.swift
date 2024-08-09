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
	@MainActor static let shared = Navigator()

	var path: [ViewPath] = []
	var showTaskBeginsWithHashtagAlert: Bool = false
	var showTaskBeginsWithAtSymbolAlert: Bool = false
	var showTaskContainsMoreThanOneAtSymbolAlert: Bool = false
	var showTaskContainsMoreThanOneCurrencySymbolAlert: Bool = false
	var showTaskBeginsWithCurrencySymbolAlert: Bool = false
	var showCurrencyNotValidNumberAlert: Bool = false

	func openView(_ viewPath: ViewPath) {
		if viewPath == .home {
			path = []
		} else {
			path.append(viewPath)
		}
	}
}
