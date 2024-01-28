//
//  TimerHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import SwiftData
import Foundation
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
    var showTaskBeginsWithHashtagAlert = false
    
    func start() {
        if !StopWatchHelper.shared.isRunning {
            if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
                if !TaskTagsInput.sharedInstance.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, TaskTagsInput.sharedInstance.text.trimmingCharacters(in: .whitespaces).first != "#" {
                    // Show confirmation to start timer
                    
                    StopWatchHelper.shared.start()
                    onStart(nameAndTags: TaskTagsInput.sharedInstance.text)
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
                } else {
                    showTaskBeginsWithHashtagAlert = true
                }
            }
        }
    }
    
    func stop(stopTime: Date) {
        StopWatchHelper.shared.stop()
        onStop(taskStopTime: stopTime)
        TaskTagsInput.sharedInstance.text = ""
        
        // Refresh the viewContext if the timer goes past midnight
        let startDate = Calendar.current.dateComponents([.day], from: startTime)
        let stopDate = Calendar.current.dateComponents([.day], from: Date.now)
        if startDate.day != stopDate.day {
            persistenceController.container.viewContext.refreshAllObjects()
        }
        
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
    
    func setStartTime(start: Date) {
        startTime = start
    }
    
    func setStopTime(stop: Date) {
        stopTime = stop
    }
    
    // TODO: Remove or change this function
    func onStart(nameAndTags: String) {
        self.nameAndTags = nameAndTags
        setStartTime(start: Date.now)
        separateTags()
    }
    
    func onStop(taskStopTime: Date) {
        setStopTime(stop: taskStopTime)
        
        let task = FurTask(context: persistenceController.container.viewContext)
        task.id = UUID()
        task.name = taskName
        task.startTime = startTime
        task.stopTime = stopTime
        task.tags = taskTags
        try? persistenceController.container.viewContext.save()
    }
    
    func separateTags() {
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
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
