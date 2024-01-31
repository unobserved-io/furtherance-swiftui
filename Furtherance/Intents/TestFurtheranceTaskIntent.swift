//
//  TestFurtheranceTaskIntent.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 31/1/24.
//

import AppIntents
import Foundation

struct TestFurtheranceTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Test Furtherance Task"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Navigator.shared.openView(.home)
        return .result()
    }
}
