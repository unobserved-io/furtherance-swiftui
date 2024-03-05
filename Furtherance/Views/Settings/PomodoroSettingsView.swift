//
//  PomodoroSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct PomodoroSettingsView: View {
    @ObservedObject var storeModel = StoreModel.shared
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25
    @AppStorage("pomodoroMoreTime") private var pomodoroMoreTime = 5
    @AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime = 5
    
    @State private var stopWatchHelper = StopWatchHelper.shared
    @State private var earliestPomodoroTime = EarliestPomodoroTime.shared
    
    var body: some View {
        Form {
            BuyProView()

            Section {
                HStack {
                    Text("Countdown timer")
                    Spacer()
                    Toggle("Countdown timer", isOn: $pomodoro)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(stopWatchHelper.isRunning && !pomodoro)
                        .onChange(of: pomodoro) { _, newVal in
                            if !newVal && stopWatchHelper.isRunning {
                                stopWatchHelper.invalidatePomodoroTimer()
                                earliestPomodoroTime.invalidateTimer()
                            }
                        }
                }
    #if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
    #endif

                HStack {
                    Text("Timer length")
                    Spacer()
                    Text("\(pomodoroTime)")
                        .bold()
                    Stepper("\(pomodoroTime)", value: $pomodoroTime, in: (stopWatchHelper.isRunning ? earliestPomodoroTime.minLength : 1) ... 1440)
                        .labelsHidden()
                        .disabled(!pomodoro)
                        .onChange(of: pomodoroTime) { _, newVal in
                            if stopWatchHelper.isRunning {
                                stopWatchHelper.updatePomodoroTimer()
                            }
                        }
                }
    #if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
    #endif
                
                HStack {
                    Text("Break time")
                    Spacer()
                    Text("\(pomodoroIntermissionTime)")
                        .bold()
                    Stepper("\(pomodoroIntermissionTime)", value: $pomodoroIntermissionTime, in: 1 ... 300)
                        .labelsHidden()
                        .disabled(!pomodoro || stopWatchHelper.pomodoroOnBreak)
                }
    #if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
    #endif
                
                HStack {
                    Text("Snooze by")
                    Spacer()
                    Text("\(pomodoroMoreTime)")
                        .bold()
                    Stepper("\(pomodoroMoreTime)", value: $pomodoroMoreTime, in: 1 ... 180)
                        .labelsHidden()
                        .disabled(!pomodoro)
                }
    #if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
    #endif
            } footer: {
                Text("All numbers represent minutes")
            }
        }
#if os(macOS)
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 350 : 300)
#endif
    }
}

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView()
    }
}
