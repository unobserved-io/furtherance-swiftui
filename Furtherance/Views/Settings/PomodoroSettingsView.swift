//
//  PomodoroSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct PomodoroSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var storeModel = StoreModel.shared
    
    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25
    @AppStorage("pomodoroMoreTime") private var pomodoroMoreTime = 5
    @AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime = 5
    @AppStorage("pomodoroBigBreak") private var pomodoroBigBreak = false
    @AppStorage("pomodoroBigBreakInterval") private var pomodoroBigBreakInterval = 4
    @AppStorage("pomodoroBigBreakLength") private var pomodoroBigBreakLength = 25
    
    @State private var stopWatchHelper = StopWatchHelper.shared
    @State private var earliestPomodoroTime = EarliestPomodoroTime.shared
    
    var body: some View {
        Form {
            BuyProView()
            
            Section {
                HStack {
                    Text("Countdown Timer")
                    Spacer()
                    Toggle("Countdown Timer", isOn: $pomodoro)
                        .toggleStyle(.switch)
                        .tint(colorScheme == .light ? switchColorLightTheme : switchColorDarkTheme)
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
                    Text("Timer Length")
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
                    Text("Break Time")
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
                    TextWithBadge("Snooze By")
                    Spacer()
                    Text("\(pomodoroMoreTime)")
                        .bold()
                    Stepper("\(pomodoroMoreTime)", value: $pomodoroMoreTime, in: 1 ... 180)
                        .labelsHidden()
                        .disabled(!pomodoro || storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
            } header: {
                Text("Pomodoro Timer")
            } footer: {
                Text("All numbers represent minutes")
            }
#if os(macOS)
            .padding(.bottom, 10)
#endif
            
            Section(header: TextWithBadge("Extended Break")) {
                HStack {
                    Text("Extended Breaks")
                    Spacer()
                    Toggle("Extended Breaks", isOn: $pomodoroBigBreak)
                        .toggleStyle(.switch)
                        .tint(colorScheme == .light ? switchColorLightTheme : switchColorDarkTheme)
                        .labelsHidden()
                        .disabled(!pomodoro || storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Extended Break Interval")
                        Text("Long break after X work sessions")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Text("\(pomodoroBigBreakInterval)")
                        .bold()
                    Stepper("\(pomodoroBigBreakInterval)", value: $pomodoroBigBreakInterval, in: 1 ... 50)
                        .labelsHidden()
                        .disabled(!pomodoro || !pomodoroBigBreak || storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
                
                HStack {
                    Text("Extended Break Length")
                    Spacer()
                    Text("\(pomodoroBigBreakLength)")
                        .bold()
                    Stepper("\(pomodoroBigBreakLength)", value: $pomodoroBigBreakLength, in: 1 ... 180)
                        .labelsHidden()
                        .disabled(!pomodoro || !pomodoroBigBreak || storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
                
                if stopWatchHelper.pomodoroSessions > 0 {
                    HStack {
                        Text("You've done \(stopWatchHelper.pomodoroSessions) work sessions this round")
                        Spacer()
                        Button("Reset", role: .destructive) {
                            stopWatchHelper.pomodoroSessions = 0
                        }
                        .disabled(stopWatchHelper.isRunning || storeModel.purchasedIds.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
    #if os(macOS)
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
    #endif
                }
            }
        }
#if os(macOS)
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 600 : 550)
#endif
    }
}

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView()
    }
}
