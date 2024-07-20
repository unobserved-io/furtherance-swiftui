//
//  Shortcuts.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 18.07.2024.
//

import Foundation
import SwiftData

@Model
class Shortcut {
    @Attribute(.allowsCloudEncryption) var id: UUID = UUID()
    @Attribute(.allowsCloudEncryption) var name: String = ""
    @Attribute(.allowsCloudEncryption) var tags: String = ""
    @Attribute(.allowsCloudEncryption) var project: String = ""
    @Attribute(.allowsCloudEncryption) var rate: Double = 0.0
    @Attribute(.allowsCloudEncryption) var colorHex: String = ""

    init(name: String, tags: String, project: String, rate: Double) {
        self.name = name
        self.tags = tags
        self.project = project
        self.rate = rate
    }
}
