//
//  TimerHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation
import SwiftUI
import RegexBuilder

@MainActor
final class TimerHelper {
    static let shared = TimerHelper()
    
    @AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime = 5
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
            if !TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "#",
               TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "@"
            {
                let trimmedStartTime = Date.now.trimMilliseconds
                stopWatchHelper.start(at: trimmedStartTime)
                startTime = trimmedStartTime
                nameAndTags = TaskTagsInput.shared.text
                separateTags()
                initiatePersistentTimer()
            } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "#" {
                Navigator.shared.showTaskBeginsWithHashtagAlert = true
            } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "@" {
                Navigator.shared.showTaskBeginsWithAtSymbolAlert = true
            }
        }
    }
    
    // TODO: Change "stopTime" var to at
    func stop(stopTime: Date = .now) {
        /// Stop the timer and perform relative actions
        stopWatchHelper.stop()
        self.stopTime = stopTime
        updateTaskAndTagsIfChanged()
        saveTask()
        TaskTagsInput.shared.text = ""
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
        if TaskTagsInput.shared.text != nameAndTags {
            if !TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "#"
            {
                nameAndTags = TaskTagsInput.shared.text
                separateTags()
            } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "#" {
                Navigator.shared.showTaskBeginsWithHashtagAlert = true
            } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "@" {
                Navigator.shared.showTaskBeginsWithAtSymbolAlert = true
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
        TaskTagsInput.shared.text = ""
        refreshAfterMidnight()
        resetPersistentTimer()
    }
    
    private func separateTags() {
        /// Separate task from tags and save each in the relative variable
        let regex = Regex {
            "@"
            Capture {
                OneOrMore(CharacterClass.anyOf("#").inverted)
            }
        }
        if let match = nameAndTags.firstMatch(of: regex) {
            let (wholeMatch, project) = match.output
            taskProject = project.trimmingCharacters(in: .whitespaces)
            nameAndTags = nameAndTags.replacingOccurrences(of: wholeMatch, with: "")
        }

        var splitTags = nameAndTags.trimmingCharacters(in: .whitespaces).split(separator: "#")
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
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
