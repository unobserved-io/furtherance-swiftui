//
//  MacContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI

struct MacContentView: View {
    @Binding var tasksCount: Int
    @Binding var showExportCSV: Bool
    
    @ObservedObject var storeModel = StoreModel.shared

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    // TODO: Pro is required to create more than one bookmark
                    Text("Bookmarks")
                } label: {
                    Text("Bookmarks")
                }

                NavigationLink {
                    TimerView(tasksCount: $tasksCount, showExportCSV: $showExportCSV)
                } label: {
                    Text("Timer")
                }

                NavigationLink {
                    MacHistoryList()
                } label: {
                    Text("History")
                }

                NavigationLink {
                    Text("Reports")
                } label: {
                    Text("Reports")
                }
                .badge(storeModel.purchasedIds.isEmpty ? "PRO" : nil)

                NavigationLink {
                    Text("Settings")
                } label: {
                    Text("Settings")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    MacContentView(tasksCount: .constant(5), showExportCSV: .constant(false))
}
