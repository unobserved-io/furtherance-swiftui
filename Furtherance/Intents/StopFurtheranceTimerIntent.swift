//
//  StopFurtheranceTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 30/1/24.
//

import AppIntents
import SwiftUI

struct StopFurtheranceTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Furtherance Timer"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Ask for confirmation?", description: "Test description", requestValueDialog: "Stop the Furtherance timer?")
    var confirmTimer: ShouldIAsk
    
    init() {
        confirmTimer = .ask
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        if StopWatchHelper.shared.isRunning {
            if confirmTimer == .ask {
                // Show confirmation to stop timer
                try await requestConfirmation(
                    result: .result(dialog: "Stop the \(TimerHelper.shared.taskName) timer?"),
                    confirmationActionName: .custom(acceptLabel: "Stop", acceptAlternatives: [], denyLabel: "Cancel", denyAlternatives: [])
                )
            }

            TimerHelper.shared.stop()
        } else {
            return .result(dialog: "No Furtherance timer is currently running"){
                Text("")
            }
        }

        return .result(dialog: "Okay, stopping the \(TimerHelper.shared.taskName) timer.") {
            HStack {
                Image("SquareIcon")
                    .resizable()
                    .frame(width: 64.0, height: 64.0)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(formatTime(Calendar.current.dateComponents([.second], from: TimerHelper.shared.startTime, to: TimerHelper.shared.stopTime).second ?? 0))
                    .font(Font.monospacedDigit(.system(size: 50.0))())
                    .lineLimit(1)
                    .lineSpacing(0)
                    .allowsTightening(false)
                    .frame(maxHeight: 90)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
        }
    }

    private func formatTime(_ secondsElapsed: Int) -> String {
        /// Format time for stop watch clock
        let hours = secondsElapsed / 3600
        let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
        let minutes = (secondsElapsed % 3600) / 60
        let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
        let seconds = secondsElapsed % 60
        let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
        return hoursString + ":" + minutesString + ":" + secondsString
    }
}
