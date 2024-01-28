//
//  AdvancedSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var stopWatchHelper = StopWatchHelper.shared
    
    @ObservedObject var storeModel = StoreModel.shared

    @AppStorage("idleDetect") private var idleDetect = false
    @AppStorage("idleLimit") private var idleLimit = 6
    @AppStorage("totalInclusive") private var totalInclusive = false
    @AppStorage("limitHistory") private var limitHistory = true
    @AppStorage("historyListLimit") private var historyListLimit = 10
    @AppStorage("showIconBadge") private var showIconBadge = false
    #if os(iOS)
    @State private var showDeleteDialog = false
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    #endif

    var body: some View {
        Form {
            BuyProView()

#if os(macOS)
            Section(header: storeModel.purchasedIds.isEmpty ? Text("Idle (Pro)").bold() : Text("Idle").bold()) {
                HStack {
                    Text("Detect when user is idle")
                    Spacer()
                    Toggle("Detect when user is idle", isOn: $idleDetect)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .onChange(of: idleDetect) { _, newVal in
                    if newVal {
                        if !stopWatchHelper.oneSecondTimer.isValid {
                            stopWatchHelper.setOneSecondTimer()
                        }
                    } else {
                        if !showIconBadge {
                            stopWatchHelper.oneSecondTimer.invalidate()
                        }
                    }
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
                    Stepper("\(idleLimit)", value: $idleLimit, in: 1 ... 999)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty || !idleDetect)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
            }
#endif

            Section(header: Text("Task History").bold()) {
                HStack {
                    storeModel.purchasedIds.isEmpty ? Text("Today's total time ticks up with timer (Pro)") : Text("Today's total time ticks up with timer")
                    Spacer()
                    Toggle("Today's total time ticks up with timer", isOn: $totalInclusive)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif

                HStack {
                    storeModel.purchasedIds.isEmpty ? Text("Limit days shown in task history (Pro)") : Text("Limit days shown in task history")
                    Spacer()
                    Toggle("Limit days shown in task history", isOn: $limitHistory)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif

                HStack {
                    Text("Only show X number of days in task history (Pro):")
                    Spacer()
                    Text("\(historyListLimit)")
                        .bold()
                    Stepper("\(historyListLimit)", value: $historyListLimit, in: 10 ... 1000, step: 10)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty || !limitHistory)
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
            }
            
#if os(iOS)
            Section {
                Button("Delete entire task history", role: .destructive) {
                    if showDeleteConfirmation {
                        showDeleteDialog = true
                    } else {
                        deleteAllTasks()
                    }
                }
            }
            #endif
        }
#if os(macOS)
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 400 : 350)
        #else
        .confirmationDialog("Delete all data?", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                deleteAllTasks()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all of your saved tasks.")
        }
#endif
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView()
    }
}
