//
//  FurTaskGroup.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation
import SwiftUI

class FurTaskGroup: Identifiable, ObservableObject {
    var name: String
    var project: String
    var tags: String
    var rate: Double
    var tasks: [FurTask] = []
    var date: String
    var totalTime: Int

    init(task: FurTask) {
        name = task.name ?? "Unknown"
        project = task.project ?? ""
        tags = task.tags ?? ""
        rate = task.rate ?? 0.0
        date = localDateFormatter.string(from: task.startTime ?? Date.now)
        tasks.append(task)
        totalTime = Calendar.current.dateComponents([.second], from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now).second ?? 0
    }

    func add(task: FurTask) {
        totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now).second ?? 0)
        tasks.append(task)
    }

    func sortTasks() {
        tasks.sort(by: { $0.startTime ?? Date.now > $1.startTime ?? Date.now })
    }
    
    func isEqual(to task: FurTask) -> Bool {
        if name == task.name,
           project == task.project,
           tags == task.tags,
           rate == task.rate {
            return true
        } else {
            return false
        }
    }
}
