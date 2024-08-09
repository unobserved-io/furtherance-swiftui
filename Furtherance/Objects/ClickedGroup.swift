//
//  ClickedGroup.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Foundation

class ClickedGroup: ObservableObject {
	@Published var taskGroup: FurTaskGroup?

	init(taskGroup: FurTaskGroup?) {
		self.taskGroup = taskGroup
	}
}
