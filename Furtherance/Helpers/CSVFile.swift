//
//  CSVFile.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 6/16/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVFile: FileDocument {
	static let readableContentTypes = [UTType.commaSeparatedText]
	static let writableContentTypes = [UTType.commaSeparatedText]
	var text = ""

	init(initialText: String = "") {
		text = initialText
	}

	// This initializer loads data that has been saved previously
	init(configuration: ReadConfiguration) throws {
		if let data = configuration.file.regularFileContents {
			text = String(decoding: data, as: UTF8.self)
		}
	}

	// This will be called when the system wants to write our data to disk
	func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
		let data = Data(text.utf8)
		return FileWrapper(regularFileWithContents: data)
	}
}
