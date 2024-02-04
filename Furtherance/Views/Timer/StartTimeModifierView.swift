//
//  StartTimeModifierView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

struct StartTimeModifierView: View {
    @AppStorage("pomodoro") private var pomodoro = false

    @State private var earliestPomodoroTime = EarliestPomodoroTime.shared

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
        .padding(.top, 5)
    }
}

#Preview {
    StartTimeModifierView()
}
