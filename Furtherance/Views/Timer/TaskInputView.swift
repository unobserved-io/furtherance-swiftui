//
//  TaskInputView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

struct TaskInputView: View {
    @StateObject var taskTagsInput = TaskTagsInput.shared
    
    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
    
    let timerHelper = TimerHelper.shared
    @State private var stopWatchHelper = StopWatchHelper.shared
    
    var body: some View {
        TextField("Task Name @Project #tag #another tag $hourly rate", text: $taskTagsInput.text)
            .disabled(stopWatchHelper.pomodoroOnBreak)
        #if os(iOS)
        .disableAutocorrection(true)
        .frame(height: 40)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)
        )
        #else
        .textFieldStyle(RoundedBorderTextFieldStyle())
        #endif
        .onChange(of: taskTagsInput.debouncedText) { _, newVal in
            if StopWatchHelper.shared.isRunning {
                if newVal != timerHelper.nameAndTags {
                    if !newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       newVal.trimmingCharacters(in: .whitespaces).first != "#",
                       newVal.trimmingCharacters(in: .whitespaces).first != "@",
                       newVal.trimmingCharacters(in: .whitespaces).first != Character(chosenCurrency),
                       TaskTagsInput.shared.text.count(where: { $0 == "@" }) < 2,
                       TaskTagsInput.shared.text.count(where: { $0 == Character(chosenCurrency) }) < 2
                    {
                        timerHelper.updateTaskAndTagsIfChanged()
                        #if os(iOS)
                        timerHelper.updatePersistentTimerTaskName()
                        #endif
                    }
                }
            }
        }
    }
}

#Preview {
    TaskInputView()
}
