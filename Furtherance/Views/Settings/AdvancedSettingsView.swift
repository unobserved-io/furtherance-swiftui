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
            Section(header: TextWithBadge("Idle")) {
                HStack {
                    Text("Idle Detection")
                    Spacer()
                    Toggle("Idle Detection", isOn: $idleDetect)
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
                    Text("Minutes Until Idle:")
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

            Section(header: TextWithBadge("Task History")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Dynamic Total")
                        Text("Today's total time ticks up with timer")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Toggle("Dynamic Total", isOn: $totalInclusive)
                        .toggleStyle(.switch)
                        .tint(colorScheme == .light ? switchColorLightTheme : switchColorDarkTheme)
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
                    Text("Limit History")
                    Spacer()
                    Toggle("Limit History", isOn: $limitHistory)
                        .toggleStyle(.switch)
                        .tint(colorScheme == .light ? switchColorLightTheme : switchColorDarkTheme)
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
                    Text("Days To Show")
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
                Button("Delete All History", role: .destructive) {
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
