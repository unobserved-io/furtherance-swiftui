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
    @Attribute(.allowsCloudEncryption) var isRunning: Bool?
    @Attribute(.allowsCloudEncryption) var startTime: Date?
    @Attribute(.allowsCloudEncryption) var taskName: String?
    @Attribute(.allowsCloudEncryption) var taskTags: String?
    @Attribute(.allowsCloudEncryption) var nameAndTags: String?

    init() {
        self.isRunning = false
        self.startTime = nil
        self.taskName = nil
        self.taskTags = nil
        self.nameAndTags = nil
    }
}
