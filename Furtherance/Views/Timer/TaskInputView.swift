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
    }
}

#Preview {
    TaskInputView()
}
