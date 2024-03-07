//
//  TimeDisplayView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 1/10/24.
//

import SwiftUI

struct TimeDisplayView: View {
    @State private var stopWatchHelper = StopWatchHelper.shared

    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25

    var body: some View {
        /// This is in its own view for performance. Updating the Pomodoro time is far faster this way
        if stopWatchHelper.isRunning {
            Text(
                timerInterval: stopWatchHelper.startTime ... stopWatchHelper.stopTime,
                countsDown: pomodoro
            )
            .font(Font.monospacedDigit(.system(size: 80.0))())
            .lineLimit(1)
            .lineSpacing(0)
            .allowsTightening(false)
            .frame(maxHeight: 90)
            .padding(.horizontal)
            .foregroundStyle(stopWatchHelper.pomodoroOnBreak ? .red : .primary)
        } else {
            Text(pomodoro ? (DateComponentsFormatter().string(from: Double(pomodoroTime * 60)) ?? "0:00") : "0:00")
                .font(Font.monospacedDigit(.system(size: 80.0))())
                .lineLimit(1)
                .lineSpacing(0)
                .allowsTightening(false)
                .frame(maxHeight: 90)
                .padding(.horizontal)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    TimeDisplayView()
}
