//
//  SettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Combine
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("idleDetect") private var idleDetect = false
    @AppStorage("idleLimit") private var idleLimit = 6
    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25
    @AppStorage("showIconBadge") private var showIconBadge = false
    @AppStorage("totalInclusive") private var totalInclusive = false
        
    var body: some View {
        ScrollView {
            Form {
                Section(header: Text("General").bold()) {
                    HStack {
                        storeModel.purchasedIds.isEmpty ? Text("Show icon badge when timer is running (Pro)") : Text("Show icon badge when timer is running")
                        Spacer()
                        Toggle("Show icon badge when timer is running", isOn: $showIconBadge)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .disabled(storeModel.purchasedIds.isEmpty)
                    }
                    .onChange(of: showIconBadge) { newVal in
                        if !newVal {
                            NSApp.dockTile.badgeLabel = nil
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
                    
                    HStack {
                        storeModel.purchasedIds.isEmpty ? Text("Today's total time ticks up with timer (Pro)") : Text("Today's total time ticks up with timer")
                        Spacer()
                        Toggle("Today's total time ticks up with timer", isOn: $totalInclusive)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .disabled(storeModel.purchasedIds.isEmpty)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
                }
                
                Section(header: storeModel.purchasedIds.isEmpty ? Text("Idle (Pro)").bold() : Text("Idle").bold()) {
                    HStack {
                        Text("Detect when user is idle")
                        Spacer()
                        Toggle("Detect when user is idle", isOn: $idleDetect)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .disabled(storeModel.purchasedIds.isEmpty)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
                    
                    HStack {
                        Text("Minutes before user is idle:")
                        Spacer()
                        Text("\(idleLimit)")
                            .bold()
                        Stepper("\(idleLimit)", value: $idleLimit, in: 1...999)
                            .labelsHidden()
                            .disabled(storeModel.purchasedIds.isEmpty)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
                }

                Section(header: Text("Pomodoro").bold()) {
                    HStack {
                        Text("Countdown timer")
                        Spacer()
                        Toggle("Countdown timer", isOn: $pomodoro)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: pomodoro) { value in
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
                        Stepper("\(pomodoroTime)", value: $pomodoroTime, in: 1...1440)
                            .labelsHidden()
                            .onChange(of: pomodoroTime) { value in
                                StopWatch.sharedInstance.getPomodoroTime()
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    .padding()
                    .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                    .cornerRadius(20)
                }
                
                if storeModel.purchasedIds.isEmpty {
                    if let product = storeModel.products.first {
                        Text("Unlock the Pro version to gain access to all features.")
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)
                            .italic()
                        HStack {
                            Button(action: {
                                Task {
                                    if storeModel.purchasedIds.isEmpty {
                                        try await storeModel.purchase()
                                    }
                                }
                            }) {
                                Text("Buy Pro \(product.displayPrice)")
                            }
                            .keyboardShortcut(.defaultAction)
                            Button(action: {
                                Task {
                                    try await AppStore.sync()
                                }
                            }) {
                                Text("Restore Purchase")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Spacer()
            }
        }
        .frame(minWidth: 250, idealWidth: 400, minHeight: 320, idealHeight: 450)
        .padding()
        .onAppear() {
            Task {
                try await storeModel.fetchProducts()
            }
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

