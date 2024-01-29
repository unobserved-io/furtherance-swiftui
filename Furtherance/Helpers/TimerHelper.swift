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
            if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
                if !TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "#"
                {
                    StopWatchHelper.shared.start()
                    startTime = Date.now
                    nameAndTags = TaskTagsInput.shared.text
                    separateTags()
                    
                    #if os(iOS)
                    // Initiate/store persistent timer values
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
                    #endif
                } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first == "#" {
                    Navigator.shared.showTaskBeginsWithHashtagAlert = true
                }
            }
        }
    }
    
    func stop(stopTime: Date) {
        /// Stop the timer and perform relative actions
        StopWatchHelper.shared.stop()
        self.stopTime = stopTime
        saveTask()
        TaskTagsInput.shared.text = ""
        
        refreshAfterMidnight()
        
        resetPersistentTimer()
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
    
    private func refreshAfterMidnight() {
        /// Refresh the viewContext if the timer goes past midnight
        let startDate = Calendar.current.dateComponents([.day], from: startTime)
        let stopDate = Calendar.current.dateComponents([.day], from: Date.now)
        if startDate.day != stopDate.day {
            persistenceController.container.viewContext.refreshAllObjects()
        }
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
