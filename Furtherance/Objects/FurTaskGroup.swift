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
    var tags: String
    var tasks: [FurTask] = []
    var totalTime: Int

    init(task: FurTask) {
        name = task.name!
        tags = task.tags!
        tasks.append(task)
        totalTime = Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0
    }

    func add(task: FurTask) {
        totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        tasks.append(task)
    }
}
