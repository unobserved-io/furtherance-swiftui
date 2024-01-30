//
//  OpenFurtherance.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 26/1/24.
//

import AppIntents
import Foundation

struct OpenFurtheranceTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Furtherance Timer"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Navigator.shared.openView(.home)
        return .result()
    }
}
