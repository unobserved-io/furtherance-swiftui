//
//  PomodoroSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct PomodoroSettingsView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25

    var body: some View {
        Form {
            BuyProView()

            HStack {
                Text("Countdown timer")
                Spacer()
                Toggle("Countdown timer", isOn: $pomodoro)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: pomodoro) { _ in
                        StopWatch.sharedInstance.getPomodoroTime()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
            .padding()
            .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
            .cornerRadius(20)

            HStack {
                Text("Start time in minutes:")
                Spacer()
                Text("\(pomodoroTime)")
                    .bold()
                Stepper("\(pomodoroTime)", value: $pomodoroTime, in: 1 ... 1440)
                    .labelsHidden()
                    .onChange(of: pomodoroTime) { _ in
                        StopWatch.sharedInstance.getPomodoroTime()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
            .padding()
            .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
            .cornerRadius(20)
        }
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 200 : 150)
    }
}

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView()
    }
}
