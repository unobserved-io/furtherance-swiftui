//
//  PersistentTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 21/1/24.
//

import Foundation
import SwiftData

@Model
public class PersistentTimer {
    @Attribute(.allowsCloudEncryption) var isRunning: Bool?
    @Attribute(.allowsCloudEncryption) var isIntermission: Bool?
    @Attribute(.allowsCloudEncryption) var intermissionTime: Int?
    @Attribute(.allowsCloudEncryption) var startTime: Date?
    @Attribute(.allowsCloudEncryption) var taskName: String?
    @Attribute(.allowsCloudEncryption) var taskTags: String?
    @Attribute(.allowsCloudEncryption) var nameAndTags: String?

    init() {
        self.isRunning = false
        self.isIntermission = false
        self.intermissionTime = 5
        self.startTime = nil
        self.taskName = nil
        self.taskTags = nil
        self.nameAndTags = nil
    }
}

public extension PersistentTimer {
    static let container = try! ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: false)])
    
    static let schema = SwiftData.Schema([
        PersistentTimer.self,
    ])
}
