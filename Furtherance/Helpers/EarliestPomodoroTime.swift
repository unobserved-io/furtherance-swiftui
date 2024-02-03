//
//  EarliestPomodoroTime.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

@Observable
class EarliestPomodoroTime {
    var minDate: Date = .now
    @ObservationIgnored var timer = Timer()
    
    @ObservationIgnored @AppStorage("pomodoro") private var pomodoro = false
    @ObservationIgnored @AppStorage("pomodoroTime") private var pomodoroTime = 25
    
    init() {
        if pomodoro {
            setTimer()
        }
    }
    
    func setTimer() {
        invalidateTimer()
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 59, repeats: true) { _ in
                self.minDate = Calendar.current.date(byAdding: .minute, value: -(self.pomodoroTime - 1), to: .now) ?? StopWatchHelper.shared.startTime
            }
        }
    }
    
    func invalidateTimer() {
        timer.invalidate()
    }
    
    deinit {
        invalidateTimer()
    }
}
