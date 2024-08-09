//
//  RuntimeError.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 23.07.2024.
//

import Foundation

struct RuntimeError: LocalizedError {
	let description: String

	init(_ description: String) {
		self.description = description
	}

	var errorDescription: String? {
		description
	}
}
