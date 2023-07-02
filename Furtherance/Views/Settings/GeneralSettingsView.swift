//
//  GeneralSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("showIconBadge") private var showIconBadge = false
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("showTags") private var showTags = true
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true

    var body: some View {
        Form {
            BuyProView()

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
                Text("Show delete confirmation")
                Spacer()
                Toggle("Show delete confirmation", isOn: $showDeleteConfirmation)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
            .padding()
            .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
            .cornerRadius(20)
            
            Section(header: Text("Task History").bold()) {
                HStack {
                    storeModel.purchasedIds.isEmpty ? Text("Show tags (Pro)") : Text("Show tags")
                    Spacer()
                    Toggle("Show tags", isOn: $showTags)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
                
                HStack {
                    storeModel.purchasedIds.isEmpty ? Text("Show seconds (Pro)") : Text("Show seconds")
                    Spacer()
                    Toggle("Show seconds", isOn: $showSeconds)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
                
                HStack {
                    storeModel.purchasedIds.isEmpty ? Text("Show daily time sum (Pro)") : Text("Show daily time sum")
                    Spacer()
                    Toggle("Show daily time sum", isOn: $showDailySum)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
            }
        }
        .padding(20)
        .frame(width: 400, height: storeModel.purchasedIds.isEmpty ? 400 : 350)
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
