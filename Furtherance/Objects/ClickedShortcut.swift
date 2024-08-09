//
//  ClickedShortcut.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 20.07.2024.
//

import Foundation

class ClickedShortcut: ObservableObject {
	@Published var shortcut: Shortcut?

	init(shortcut: Shortcut?) {
		self.shortcut = shortcut
	}
}
