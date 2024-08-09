//
//  Globals.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/12/23.
//

import CoreData
import OSLog
import SwiftUI

let logger = Logger(subsystem: "io.unobserved.debugger", category: "Furtherance")

let switchColorLightTheme: Color = .accent
let switchColorDarkTheme: Color = .accent

let localDateTimeFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
	return formatter
}()

let localDateFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd"
	return formatter
}()

func formatTimeShort(_ totalSeconds: Int) -> String {
	/// Format input seconds into a time format that does not include hours if there isn't any, and doesn't pad the hours
	let hours = totalSeconds / 3600
	let hoursString = String(hours)
	let minutes = (totalSeconds % 3600) / 60
	let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
	let seconds = totalSeconds % 60
	let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
	if hours > 0 {
		return hoursString + ":" + minutesString + ":" + secondsString
	} else {
		return minutesString + ":" + secondsString
	}
}

func formatTimeLong(_ totalSeconds: Int) -> String {
	/// Format input seconds into a time format that includes padded hours
	let hours = totalSeconds / 3600
	let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
	let minutes = (totalSeconds % 3600) / 60
	let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
	let seconds = totalSeconds % 60
	let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
	return hoursString + ":" + minutesString + ":" + secondsString
}

func formatTimeLongWithoutSeconds(_ totalSeconds: Int) -> String {
	/// Format input seconds into a time format that does not include hours if there isn't any, and doesn't pad the hours
	let hours = totalSeconds / 3600
	let hoursString = String(hours)
	let minutes = (totalSeconds % 3600) / 60
	let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
	if minutes < 1 {
		return "< 0:01"
	} else {
		return hoursString + ":" + minutesString
	}
}

func deleteAllTasks() {
	do {
		let fetchRequest: NSFetchRequest<NSFetchRequestResult>
		fetchRequest = NSFetchRequest(entityName: "FurTask")

		let deleteRequest = NSBatchDeleteRequest(
			fetchRequest: fetchRequest
		)
		deleteRequest.resultType = .resultTypeObjectIDs

		let batchDelete = try PersistenceController.shared.container.viewContext.execute(deleteRequest)
			as? NSBatchDeleteResult

		guard let deleteResult = batchDelete?.result
			as? [NSManagedObjectID]
		else { return }

		let deletedObjects: [AnyHashable: Any] = [
			NSDeletedObjectsKey: deleteResult,
		]

		NSManagedObjectContext.mergeChanges(
			fromRemoteContextSave: deletedObjects,
			into: [PersistenceController.shared.container.viewContext]
		)
	} catch {
		print("Error deleting all tasks: \(error)")
	}
}

func separateTags(rawString: String) -> String {
	var splitTags = rawString.trimmingCharacters(in: .whitespaces).split(separator: "#")
	// Trim each element and lowercase them
	for i in splitTags.indices {
		splitTags[i] = .init(splitTags[i].trimmingCharacters(in: .whitespaces).lowercased())
	}
	// Don't allow empty tags
	splitTags.removeAll(where: { $0.isEmpty })
	// Don't allow duplicate tags
	let splitTagsUnique = splitTags.uniqued()
	let splitTagsJoined = splitTagsUnique.joined(separator: " #")
	if !splitTagsJoined.trimmingCharacters(in: .whitespaces).isEmpty {
		return "#\(splitTagsJoined)"
	} else {
		return ""
	}
}

func getCurrencyCode(for currency: String) -> String {
	switch currency {
	case "$": "USD"
	default: "USD"
	}
}
