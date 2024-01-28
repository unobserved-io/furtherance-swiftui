//
//  StartFurtheranceTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 27/1/24.
//

import AppIntents
import SwiftData
import SwiftUI

struct StartFurtheranceTimer: AppIntent {
    static var title: LocalizedStringResource = "Start Furtherance Timer"
    var openAppWhenRun: Bool = false
    
    @Parameter(title: "Task", requestValueDialog: "What is the task?")
    var task: String
    @Parameter(title: "#tags", requestValueDialog: "What tags should be included?")
    var tags: String?
    
    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog & ReturnsValue<String> {
        if StopWatchHelper.shared.isRunning {
            // TODO: Implement this after converting FurTask to SwiftData
//            try await requestConfirmation(
//                result: .result(dialog: "Another Furtherance timer is currently running. Turn it off?"),
//                confirmationActionName: .turnOff
//            )
//            StopWatchHelper.shared.stop()
            
            return .result(value: task, dialog: "Failed to start a timer for \(task).") {
                Text("Stop your currently running timer before starting a new one.")
            }
        }
        
        // TODO: Do I need to do this again after the throws?
        if tags?.isEmpty ?? true {
            TaskTagsInput.sharedInstance.text = task
        } else {
            TaskTagsInput.sharedInstance.text = "\(task) \(tags!)"
        }
            
        // Start timer and store persistent timer info

        if !TaskTagsInput.sharedInstance.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, TaskTagsInput.sharedInstance.text.trimmingCharacters(in: .whitespaces).first != "#" {
            // Show confirmation to start timer
            try await requestConfirmation(
                result: .result(value: task, dialog: "Start a timer for \(task)?"),
                confirmationActionName: .start
            )
            TimerHelper.shared.start()
        } else if task.trimmingCharacters(in: .whitespaces).first == "#" {
            throw $task.needsValueError("The task name cannot start with a #. Please retype it.")
        } else {
            throw $task.needsValueError("What task are you starting?")
        }
        
        return .result(value: task, dialog: "Started a timer for \(task).") {
            HStack {
                Image(uiImage: UIImage(named: "AppIcon60x60") ?? UIImage())
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
        Summary("Start Furtherance timer with task \(\.$task) and tags \(\.$tags)")
    }
}
