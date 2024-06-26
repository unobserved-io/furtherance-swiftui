//
//  TaskInputView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/2/24.
//

import SwiftUI

struct TaskInputView: View {
    @StateObject var taskTagsInput = TaskTagsInput.shared
    
    let timerHelper = TimerHelper.shared
    @State private var stopWatchHelper = StopWatchHelper.shared
    
    var body: some View {
        TextField("Task Name #tag #another tag", text: $taskTagsInput.text)
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
                       newVal.trimmingCharacters(in: .whitespaces).first != "#"
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
