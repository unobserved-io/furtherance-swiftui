//
//  TimerHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation
import RegexBuilder
import SwiftUI

@MainActor
final class TimerHelper {
	static let shared = TimerHelper()

	@AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime = 5
	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
	@AppStorage("ptIsRunning") private var ptIsRunning: Bool = false
	@AppStorage("ptIsIntermission") private var ptIsIntermission: Bool = false
	@AppStorage("ptIsExtended") private var ptIsExtended: Bool = false
	@AppStorage("ptLastIntermissionTime") private var ptIntermissionTime: Int = 5
	@AppStorage("ptStartTime") private var ptStartTime: TimeInterval = Date.now.timeIntervalSinceReferenceDate
	@AppStorage("ptStopTime") private var ptStopTime: TimeInterval = Date.now.timeIntervalSinceReferenceDate
	@AppStorage("ptTaskName") private var ptTaskName: String = ""
	@AppStorage("ptTaskTags") private var ptTaskTags: String = ""
	@AppStorage("ptTaskProject") private var ptTaskProject: String = ""
	@AppStorage("ptNameAndTags") private var ptNameAndTags: String = ""

	let persistenceController = PersistenceController.shared
	let stopWatchHelper = StopWatchHelper.shared
	let taskTagsInput = TaskTagsInput.shared

	var startTime: Date = .now
	var stopTime: Date = .now
	var taskName: String = ""
	var taskTags: String = ""
	var taskProject: String = ""
	var taskRate: Double = 0.0
	var nameAndTags: String = ""

	func start() {
		/// Start the timer and perform relative actions
		if !stopWatchHelper.isRunning {
			if !taskTagsInput.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
			   taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != "#",
			   taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != "@",
			   taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != Character(chosenCurrency),
			   taskTagsInput.text.filter({ $0 == "@" }).count < 2,
			   taskTagsInput.text.filter({ $0 == Character(chosenCurrency) }).count < 2
			{
				if taskTagsInput.text.contains(chosenCurrency) {
					let rateRegex = Regex {
						chosenCurrency
						Capture {
							OneOrMore(CharacterClass.anyOf("#@").inverted)
						}
					}
					if let match = taskTagsInput.text.firstMatch(of: rateRegex) {
						let (_, rate) = match.output
						let modifiedRate = rate.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
						if let _ = Double(modifiedRate) {
							let trimmedStartTime = Date.now.trimMilliseconds
							stopWatchHelper.start(at: trimmedStartTime)
							startTime = trimmedStartTime
							nameAndTags = taskTagsInput.text
							separateTags()
							initiatePersistentTimer()
						}
					} else {
						Navigator.shared.showCurrencyNotValidNumberAlert = true
					}
				} else {
					let trimmedStartTime = Date.now.trimMilliseconds
					stopWatchHelper.start(at: trimmedStartTime)
					startTime = trimmedStartTime
					nameAndTags = taskTagsInput.text
					separateTags()
					initiatePersistentTimer()
				}
			} else if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first == "#" {
				Navigator.shared.showTaskBeginsWithHashtagAlert = true
			} else if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first == "@" {
				Navigator.shared.showTaskBeginsWithAtSymbolAlert = true
			} else if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first == Character(chosenCurrency) {
				Navigator.shared.showTaskBeginsWithCurrencySymbolAlert = true
			} else if taskTagsInput.text.filter({ $0 == "@" }).count >= 2 {
				Navigator.shared.showTaskContainsMoreThanOneAtSymbolAlert = true
			} else if taskTagsInput.text.filter({ $0 == Character(chosenCurrency) }).count >= 2 {
				Navigator.shared.showTaskContainsMoreThanOneCurrencySymbolAlert = true
			}
		}
	}

	func stop(at stopTime: Date = .now) {
		/// Stop the timer and perform relative actions
		stopWatchHelper.stop()
		self.stopTime = stopTime
		updateTaskAndTagsIfChanged()
		saveTask()
		taskTagsInput.text = ""
		resetAll()
		refreshAfterMidnight()
		resetPersistentTimer()
	}

	func updatePersistentTimerTaskName() {
		#if os(iOS)
			ptTaskName = taskName
			ptTaskTags = taskTags
			ptNameAndTags = nameAndTags
		#endif
	}

	func updatePersistentTimerStartTime() {
		#if os(iOS)
			ptStartTime = startTime.timeIntervalSinceReferenceDate
		#endif
	}

	func updateTaskAndTagsIfChanged() {
		if taskTagsInput.text != nameAndTags {
			if !taskTagsInput.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
			   taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != "#",
			   taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != "@",
			   taskTagsInput.text.filter({ $0 == "@" }).count < 2
			{
				nameAndTags = taskTagsInput.text
				separateTags()
			} else if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first == "#" {
				Navigator.shared.showTaskBeginsWithHashtagAlert = true
			} else if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first == "@" {
				Navigator.shared.showTaskBeginsWithAtSymbolAlert = true
			} else if taskTagsInput.text.filter({ $0 == "@" }).count >= 2 {
				Navigator.shared.showTaskContainsMoreThanOneAtSymbolAlert = true
			}
		}
	}

	func updateStartTime(to newStartTime: Date) {
		/// Update the start time in all necessary locations when it is changed by the user
		let trimmedStartTime = newStartTime.trimMilliseconds
		startTime = trimmedStartTime
		updatePersistentTimerStartTime()
		stopWatchHelper.startTime = trimmedStartTime
		stopWatchHelper.updatePomodoroTimer()
	}

	func pomodoroStartIntermission() {
		stopTime = stopWatchHelper.stopTime
		stopWatchHelper.stop()
		updateTaskAndTagsIfChanged()
		saveTask()
		refreshAfterMidnight()
		resetPersistentTimer()
		stopWatchHelper.pomodoroStartIntermission()
		initiatePersistentTimer()
	}

	func pomodoroNextWorkSession() {
		stopWatchHelper.stop()
		updateTaskAndTagsIfChanged()
		refreshAfterMidnight()
		resetPersistentTimer()
		start()
	}

	func pomodoroStopAfterBreak() {
		/// Stop the timer after just on a Pomodoro break
		stopWatchHelper.stop()
		updateTaskAndTagsIfChanged()
		taskTagsInput.text = ""
		refreshAfterMidnight()
		resetPersistentTimer()
	}

	private func separateTags() {
		/// Separate task from tags and save each in the relative variable
		var allText = nameAndTags // This stops update from running when replacing text

		// Capture and remove project
		let projectRegex = Regex {
			"@"
			Capture {
				OneOrMore(CharacterClass.anyOf("#$").inverted)
			}
		}
		if let match = allText.firstMatch(of: projectRegex) {
			let (wholeMatch, project) = match.output
			taskProject = project.trimmingCharacters(in: .whitespaces)
			allText = allText.replacingOccurrences(of: wholeMatch, with: "")
		}

		// Capture and remove rate
		let rateRegex = Regex {
			chosenCurrency
			Capture {
				OneOrMore(CharacterClass.anyOf("#@").inverted)
			}
		}
		if let match = allText.firstMatch(of: rateRegex) {
			let (wholeMatch, rate) = match.output
			let modifiedRate = rate.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
			taskRate = Double(modifiedRate) ?? 0.0
			allText = allText.replacingOccurrences(of: wholeMatch, with: "")
		}

		var splitTags = allText.trimmingCharacters(in: .whitespaces).split(separator: "#")
		// Get and remove task name from tags list
		taskName = splitTags[0].trimmingCharacters(in: .whitespaces)
		splitTags.remove(at: 0)
		// Trim each element and lowercase them
		for i in splitTags.indices {
			splitTags[i] = .init(splitTags[i].trimmingCharacters(in: .whitespaces).lowercased())
		}
		// Don't allow empty tags
		splitTags.removeAll(where: { $0.isEmpty })
		// Don't allow duplicate tags
		let splitTagsUnique = splitTags.uniqued()
		taskTags = splitTagsUnique.joined(separator: " #")
		if !taskTags.trimmingCharacters(in: .whitespaces).isEmpty {
			taskTags = "#\(taskTags)"
		}
	}

	private func saveTask() {
		/// Create a new task in Core Data
		let task = FurTask(context: persistenceController.container.viewContext)
		task.id = UUID()
		task.name = taskName
		task.startTime = startTime
		task.stopTime = stopTime
		task.tags = taskTags
		task.project = taskProject
		task.rate = taskRate
		try? persistenceController.container.viewContext.save()
	}

	private func refreshAfterMidnight() {
		/// Refresh the viewContext if the timer goes past midnight
		let startDate = Calendar.current.dateComponents([.day], from: startTime)
		let stopDate = Calendar.current.dateComponents([.day], from: Date.now)
		if startDate.day != stopDate.day {
			persistenceController.container.viewContext.refreshAllObjects()
		}
	}

	private func initiatePersistentTimer() {
		/// Initiate/store persistent timer values
		#if os(iOS)
			ptIsRunning = true
			ptTaskName = taskName
			ptTaskTags = taskTags
			ptTaskProject = taskProject
			ptNameAndTags = nameAndTags

			if stopWatchHelper.pomodoroOnBreak {
				ptIsIntermission = true
				ptIntermissionTime = stopWatchHelper.intermissionTime
				ptStartTime = stopWatchHelper.startTime.timeIntervalSinceReferenceDate
			} else {
				ptIsIntermission = false
				ptStartTime = startTime.timeIntervalSinceReferenceDate
			}
		#endif
	}

	private func resetPersistentTimer() {
		#if os(iOS)
			ptIsRunning = false
			ptIsIntermission = false
			ptIsExtended = false
			ptIntermissionTime = 5
			ptStartTime = Date.now.timeIntervalSinceReferenceDate
			ptStopTime = Date.now.timeIntervalSinceReferenceDate
			ptTaskName = ""
			ptTaskTags = ""
			ptTaskProject = ""
			ptNameAndTags = ""
		#endif
	}

	private func resetAll() {
		taskName = ""
		taskProject = ""
		taskTags = ""
		taskRate = 0.0
	}
}

extension Sequence where Element: Hashable {
	func uniqued() -> [Element] {
		var set = Set<Element>()
		return filter { set.insert($0).inserted }
	}
}
