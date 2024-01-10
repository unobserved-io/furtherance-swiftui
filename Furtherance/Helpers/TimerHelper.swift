//
//  TimerHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import Foundation
import SwiftUI

final class TimerHelper {
    static let sharedInstance = TimerHelper()
    let persistenceController = PersistenceController.shared
    
    var startTime: Date = .now
    var stopTime: Date = .now
    var taskName: String = ""
    var taskTags: String = ""
    var nameAndTags: String = ""
    
    func setStartTime(start: Date) {
        startTime = start
    }
    
    func setStopTime(stop: Date) {
        stopTime = stop
    }
    
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
