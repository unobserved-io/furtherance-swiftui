//
//  OpenFurtherance.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 26/1/24.
//

import Foundation
import AppIntents

struct OpenFurtheranceTimer: AppIntent {
    static var title: LocalizedStringResource = "Open Furtherance Timer"
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        Navigator.shared.openView(.home)
        return .result()
    }
}
