//
//  StartTimeModifierView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

struct StartTimeModifierView: View {
    @AppStorage("pomodoro") private var pomodoro = false

    var earliestPomodoroTime = EarliestPomodoroTime()

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .help("Start time")
            DatePicker(
                "Start time",
                selection: Binding(get: {
                                       TimerHelper.shared.startTime
                                   },
                                   set: { newValue in
                                       TimerHelper.shared.updateStartTime(to: newValue)
                                   }),
                in: (pomodoro ? earliestPomodoroTime.minDate : .now.startOfDay) ... .now,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
        }
        .onChange(of: pomodoro) { _, newVal in
            if newVal {
                earliestPomodoroTime.setTimer()
            } else {
                earliestPomodoroTime.invalidateTimer()
            }
        }
        .padding(.top, 5)
    }
}

#Preview {
    StartTimeModifierView()
}
