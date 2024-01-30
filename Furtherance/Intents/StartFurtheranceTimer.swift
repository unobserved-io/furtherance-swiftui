//
//  StartFurtheranceTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 27/1/24.
//

import AppIntents
import SwiftData
import SwiftUI


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

struct StartFurtheranceTimer: AppIntent {
    static var title: LocalizedStringResource = "Start Furtherance Timer"
    
    #if os(iOS)
    static var openAppWhenRun: Bool = false
    #elseif os(macOS)
    static var openAppWhenRun: Bool = true
    #endif
    
    @Parameter(title: "Task #tags", requestValueDialog: "Task name and tags")
    var taskTags: String
    @Parameter(title: "Ask to start timer each time?", description: "Test description", requestValueDialog: "Start timer confirmation")
    var confirmTimer: ShouldIAsk
    
    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog & ReturnsValue<String> {
        if StopWatchHelper.shared.isRunning {
            try await requestConfirmation(
                result: .result(dialog: "Another Furtherance timer is currently running. Turn it off?"),
                confirmationActionName: .turnOff
            )
            TimerHelper.shared.stop()
        }
        
        TaskTagsInput.shared.text = taskTags
            
        // Start timer and store persistent timer info
        if !TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, TaskTagsInput.shared.text.trimmingCharacters(in: .whitespaces).first != "#" {
            
            if confirmTimer == .ask {
                // Show confirmation to start timer
                try await requestConfirmation(
                    result: .result(value: taskTags, dialog: "Start a timer for \(taskTags)?"),
                    confirmationActionName: .start
                )
            }
            
            TimerHelper.shared.start()
        } else if taskTags.trimmingCharacters(in: .whitespaces).first == "#" {
            throw $taskTags.needsValueError("The task name cannot start with a #. Please retype it.")
        } else {
            throw $taskTags.needsValueError("What task are you starting?")
        }
        
        return .result(value: taskTags, dialog: "Started a timer for \(taskTags).") {
            HStack {
                Image("SquareIcon")
                    .resizable()
                    .frame(width: 64.0, height: 64.0)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(
                    timerInterval: Date.now ... Date.distantFuture,
                    countsDown: false
                )
                .font(Font.monospacedDigit(.system(size: 60.0))())
                .lineLimit(1)
                .lineSpacing(0)
                .allowsTightening(false)
                .frame(maxHeight: 90)
                .padding(.horizontal)
            }
            .padding(.horizontal)
        }
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start Furtherance timer for \(\.$taskTags)") {
            \.$confirmTimer
        }
    }
}
