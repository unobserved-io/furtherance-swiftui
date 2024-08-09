//
//  ClickedTask.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Foundation

class ClickedTask: ObservableObject {
	@Published var task: FurTask?

	init(task: FurTask?) {
		self.task = task
	}
}
