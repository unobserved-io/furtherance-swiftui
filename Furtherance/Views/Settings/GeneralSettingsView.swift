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
    @AppStorage("totalInclusive") private var totalInclusive = false
    
    var body: some View {
        Form {
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
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
