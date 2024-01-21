//
//  PersistentTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 21/1/24.
//

import Foundation
import SwiftData

@Model
final class PersistentTimer {
    var isRunning: Bool?
    var startTime: Date?
    var taskName: String?
    var taskTags: String?
    var nameAndTags: String?

    init() {
        self.isRunning = false
        self.startTime = nil
        self.taskName = nil
        self.taskTags = nil
        self.nameAndTags = nil
    }
}
