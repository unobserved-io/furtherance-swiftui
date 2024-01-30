//
//  ShouldIAskAppEnum.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 30/1/24.
//

import AppIntents
import Foundation

enum ShouldIAsk: String {
    case ask
    case dontAsk
}

extension ShouldIAsk: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Ask"

    static var caseDisplayRepresentations: [ShouldIAsk: DisplayRepresentation] = [
        .ask: "Ask",
        .dontAsk: "Don't Ask",
    ]
}
