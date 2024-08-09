//
//  EarliestPomodoroTime.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

@Observable @MainActor
class EarliestPomodoroTime {
	static var shared = EarliestPomodoroTime()

	var minDate: Date = .now
	var minLength: Int = 1
	@ObservationIgnored var timer = Timer()

	@ObservationIgnored @AppStorage("pomodoro") private var pomodoro = false
	@ObservationIgnored @AppStorage("pomodoroTime") private var pomodoroTime = 25

	func setTimer() {
		invalidateTimer()
		minDate = Calendar.current.date(byAdding: .minute, value: -(pomodoroTime - 1), to: .now) ?? StopWatchHelper.shared.startTime
		timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
			Task {
				await self.updateMinimums()
			}
		}
	}

	func invalidateTimer() {
		timer.invalidate()
		minLength = 1
	}

	private func updateMinimums() {
		minDate = Calendar.current.date(byAdding: .minute, value: -(pomodoroTime - 1), to: .now) ?? StopWatchHelper.shared.startTime
		minLength = (Int(Date.now.timeIntervalSince1970 - StopWatchHelper.shared.startTime.timeIntervalSince1970) / 60) + 1
	}

	deinit {
		Task {
			await self.invalidateTimer()
		}
	}
}
