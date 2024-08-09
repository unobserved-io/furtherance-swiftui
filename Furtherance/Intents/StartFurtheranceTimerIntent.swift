//
//  StartFurtheranceTimerIntent.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 27/1/24.
//

import AppIntents
import SwiftUI

struct StartFurtheranceTimerIntent: AppIntent {
	static let title: LocalizedStringResource = "Start Furtherance Timer"

	#if os(iOS)
		static let openAppWhenRun: Bool = false
	#elseif os(macOS)
		static let openAppWhenRun: Bool = true
	#endif

	@Parameter(title: "Task #tags", requestValueDialog: "What task and tags?")
	var taskTags: String
	@Parameter(title: "Ask for confirmation?", description: "Test description", requestValueDialog: "Start the timer?")
	var confirmTimer: ShouldIAsk

	init() {
		confirmTimer = .ask
	}

	@MainActor
	func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog & ReturnsValue<String> {
		if StopWatchHelper.shared.isRunning {
			try await requestConfirmation(
				result: .result(dialog: "Do you want to stop the current Furtherance timer?"),
				confirmationActionName: .custom(acceptLabel: "Stop", acceptAlternatives: [], denyLabel: "Cancel", denyAlternatives: [])
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
			throw $taskTags.needsValueError("The task name cannot start with a #. Please try again.")
		} else {
			throw $taskTags.needsValueError("What task are you starting?")
		}

		return .result(value: taskTags, dialog: "Okay, starting a Furtherance timer for \(taskTags).") {
			HStack {
				Image("SquareIcon")
					.resizable()
					.frame(width: 64.0, height: 64.0)
					.clipShape(RoundedRectangle(cornerRadius: 12))
				Text(
					timerInterval: TimerHelper.shared.startTime ... Date.distantFuture,
					countsDown: false
				)
				.font(Font.monospacedDigit(.system(size: 55.0))())
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
