//
//  GeneralSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var storeModel = StoreModel.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var stopWatchHelper = StopWatchHelper.shared

    @AppStorage("showIconBadge") private var showIconBadge = false
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("showTags") private var showTags = true
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    @AppStorage("idleDetect") private var idleDetect = false

    var body: some View {
        Form {
            BuyProView()
            
            Section("Interface ") {
#if os(macOS)
                HStack {
                    VStack(alignment: .leading) {
                        TextWithBadge("Show Icon Badge")
                    }
                    Spacer()
                    Toggle("Show Icon Badge", isOn: $showIconBadge)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .onChange(of: showIconBadge) { _, newVal in
                    if newVal {
                        if !stopWatchHelper.oneSecondTimer.isValid {
                            stopWatchHelper.setOneSecondTimer()
                        }
                    } else {
                        NSApp.dockTile.badgeLabel = nil
                        if !idleDetect {
                            stopWatchHelper.oneSecondTimer.invalidate()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
                
                HStack {
                    Text("Show Delete Confirmation")
                    Spacer()
                    Toggle("Show Delete Confirmation", isOn: $showDeleteConfirmation)
                        .toggleStyle(.switch)
                        .tint(colorScheme == .light ? switchColorLightTheme : switchColorDarkTheme)
                        .labelsHidden()
                }
#if os(macOS)
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
#endif
            }

            Section(header: TextWithBadge("Task History")) {
                HStack {
                    Text("Show Tags")
                    Spacer()
                    Toggle("Show Tags", isOn: $showTags)
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
                    Text("Show Seconds")
                    Spacer()
                    Toggle("Show Seconds", isOn: $showSeconds)
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
                    Text("Show Daily Time Sum")
                    Spacer()
                    Toggle("Show Daily Time Sum", isOn: $showDailySum)
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
            }
        }
#if os(macOS)
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 400 : 350)
#endif
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
