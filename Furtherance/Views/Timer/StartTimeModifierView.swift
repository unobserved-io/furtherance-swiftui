//
//  StartTimeModifierView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

struct StartTimeModifierView: View {
    @ObservedObject var storeModel = StoreModel.shared

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
            .disabled(StopWatchHelper.shared.pomodoroExtended || storeModel.purchasedIds.isEmpty)

            if storeModel.purchasedIds.isEmpty {
                Text("PRO")
                    .padding(.vertical, 3.0)
                    .padding(.horizontal, 8.0)
                    .foregroundStyle(.background)
                    .background(RoundedRectangle(cornerRadius: 20.0).fill(.gray.opacity(0.7)))
            }
        }
        .padding(.top, 5)
    }
}

#Preview {
    StartTimeModifierView()
}
