//
//  MacTimerView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI

@MainActor
struct MacTimerView: View {
    @State private var stopWatchHelper = StopWatchHelper.shared
    @State private var showingTaskEmptyAlert = false
    
    let timerHelper = TimerHelper.shared
    
    var body: some View {
        VStack {
            TimeDisplayView()
            
            HStack {
                TaskInputView()
                    .onSubmit {
                        startStopPress()
                    }
                
                Button {
                    if stopWatchHelper.pomodoroOnBreak {
                        timerHelper.pomodoroStopAfterBreak()
                    } else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showingTaskEmptyAlert.toggle()
                    } else {
                        startStopPress()
                    }
                } label: {
                    Image(systemName: stopWatchHelper.isRunning ? "stop.fill" : "play.fill")
                }
            }
            .padding(.horizontal)
            
            if stopWatchHelper.isRunning {
                StartTimeModifierView()
            }
        }
    }
    
    private func startStopPress() {
        if stopWatchHelper.isRunning {
            timerHelper.stop(at: Date.now)
        } else {
            timerHelper.start()
        }
    }
}

#Preview {
    MacTimerView()
}
