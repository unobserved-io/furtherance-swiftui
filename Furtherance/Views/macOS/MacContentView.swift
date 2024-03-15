//
//  MacContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI

enum EditInInspector {
    case group
    case single
}

struct MacContentView: View {
    @Binding var tasksCount: Int
    @Binding var showExportCSV: Bool
    
    @ObservedObject var storeModel = StoreModel.shared
    
    @StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
    @StateObject var clickedTask = ClickedTask(task: nil)
    
    @State(initialValue: false) var showInspector: Bool
    @State(initialValue: .single) var typeToEdit: EditInInspector

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
                    MacHistoryList(showInspector: $showInspector, typeToEdit: $typeToEdit)
                        .environmentObject(clickedGroup)
                        .environmentObject(clickedTask)
                        .inspector(isPresented: $showInspector) {
                            if typeToEdit == .group {
                                GroupView()
                                    .environmentObject(clickedGroup)
                                    .padding()
                            } else {
                                TaskEditView(showInspector: $showInspector)
                                    .environmentObject(clickedTask)
                                    .padding()
                            }
                        }
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
