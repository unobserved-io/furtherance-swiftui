//
//  TimerHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation
import SwiftData
import SwiftUI

final class TimerHelper {
    static let shared = TimerHelper()
    let persistenceController = PersistenceController.shared
    let modelContext = ModelContext(PersistentTimer.container)
    
    var startTime: Date = .now
    var stopTime: Date = .now
    var taskName: String = ""
    var taskTags: String = ""
    var nameAndTags: String = ""
    
    func start() {
        /// Start the timer and perform relative actions
        if !StopWatchHelper.shared.isRunning {
            if !TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "#"
            {
                let trimmedStartTime = Date.now.trimMilliseconds
                StopWatchHelper.shared.start(at: trimmedStartTime)
                startTime = trimmedStartTime
                nameAndTags = TaskTagsInput.shared.text
                separateTags()
                initiatePersistentTimer()
            } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "#" {
                Navigator.shared.showTaskBeginsWithHashtagAlert = true
            }
        }
    }
    
    // TODO: Change "stopTime" var to at
    func stop(stopTime: Date = .now) {
        /// Stop the timer and perform relative actions
        StopWatchHelper.shared.stop()
        self.stopTime = stopTime
        updateTaskAndTagsIfChanged()
        saveTask()
        TaskTagsInput.shared.text = ""
        refreshAfterMidnight()
        resetPersistentTimer()
    }
    
    func updatePersistentTimerTaskName() {
        #if os(iOS)
        if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
            persistentTimer.first?.taskName = taskName
            persistentTimer.first?.taskTags = taskTags
            persistentTimer.first?.nameAndTags = nameAndTags
        }
        #endif
    }
    
    func updatePersistentTimerStartTime() {
        #if os(iOS)
        if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
            persistentTimer.first?.startTime = startTime
        }
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
            }
        }
    }
    
    func updateStartTime(to newStartTime: Date) {
        /// Update the start time in all necessary locations when it is changed by the user
        let trimmedStartTime = newStartTime.trimMilliseconds
        startTime = trimmedStartTime
        updatePersistentTimerStartTime()
        StopWatchHelper.shared.startTime = trimmedStartTime
        StopWatchHelper.shared.updatePomodoroTimer()
    }
    
    func pomodoroStartIntermission() {
        self.stopTime = StopWatchHelper.shared.stopTime
        StopWatchHelper.shared.stop()
        updateTaskAndTagsIfChanged()
        saveTask()
        refreshAfterMidnight()
        resetPersistentTimer()
        StopWatchHelper.shared.pomodoroStartIntermission()
    }
    
    func pomodoroNextWorkSession() {
        StopWatchHelper.shared.stop()
        updateTaskAndTagsIfChanged()
        refreshAfterMidnight()
        resetPersistentTimer()
        start()
    }
    
    func pomodoroStopAfterBreak() {
        /// Stop the timer after just on a Pomodoro break
        StopWatchHelper.shared.stop()
        updateTaskAndTagsIfChanged()
        TaskTagsInput.shared.text = ""
        refreshAfterMidnight()
        resetPersistentTimer()
    }
    
    private func separateTags() {
        /// Separate task from tags and save each in the relative variable
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
        if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
            if persistentTimer.first == nil {
                let newPersistentTimer = PersistentTimer()
                newPersistentTimer.isRunning = true
                newPersistentTimer.startTime = startTime
                newPersistentTimer.taskName = taskName
                newPersistentTimer.taskTags = taskTags
                newPersistentTimer.nameAndTags = nameAndTags
                modelContext.insert(newPersistentTimer)
            } else {
                persistentTimer.first?.isRunning = true
                persistentTimer.first?.startTime = startTime
                persistentTimer.first?.taskName = taskName
                persistentTimer.first?.taskTags = taskTags
                persistentTimer.first?.nameAndTags = nameAndTags
            }
        }
        #endif
    }
    
    private func resetPersistentTimer() {
        #if os(iOS)
        if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
            persistentTimer.first?.isRunning = false
            persistentTimer.first?.startTime = nil
            persistentTimer.first?.taskName = nil
            persistentTimer.first?.taskTags = nil
            persistentTimer.first?.nameAndTags = nil
        }
        #endif
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
