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

    @StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
    @StateObject var clickedTask = ClickedTask(task: nil)
    @StateObject var clickedShortcut = ClickedShortcut(shortcut: nil)

    @AppStorage("defaultView") private var defaultView: NavItems = .timer

    @State(initialValue: false) var showInspector: Bool
    @State(initialValue: .editTask) var inspectorView: SelectedInspectorView

    @State private var navSelection: NavItems? = .timer

    // TODO: Create one observable object for everything here that needs to be changed by multiple views
    var body: some View {
        NavigationSplitView {
            List(NavItems.allCases, id: \.self, selection: $navSelection) { navItem in
                NavigationLink(navItem.rawValue.capitalized, value: navItem)
                    .badge(navItem == .report && storeModel.purchasedIds.isEmpty ? "PRO" : nil)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if let selectedItem = navSelection {
                switch selectedItem {
                case .shortcuts: ShortcutsView(
                        showInspector: $showInspector,
                        inspectorView: $inspectorView,
                        navSelection: $navSelection
                    )
                    .environmentObject(clickedShortcut)
                case .timer: TimerView(tasksCount: $tasksCount, showExportCSV: $showExportCSV)
                case .history: MacHistoryList(
                        showInspector: $showInspector,
                        inspectorView: $inspectorView,
                        navSelection: $navSelection
                    )
                    .environmentObject(clickedGroup)
                    .environmentObject(clickedTask)
                case .report: Text("Report")
                }
            } else {
                TimerView(tasksCount: $tasksCount, showExportCSV: $showExportCSV)
            }
        }
        .inspector(isPresented: $showInspector) {
            switch inspectorView {
            case .empty:
                ContentUnavailableView("Nothing selected", systemImage: "cursorarrow.rays")
                    .toolbar {
                        if showInspector {
                            ToolbarItem {
                                Spacer()
                            }
                            ToolbarItem {
                                Button {
                                    showInspector = false
                                } label: {
                                    Image(systemName: "sidebar.trailing")
                                        .help("Hide inspector")
                                }
                            }
                        }
                    }
            case .editTaskGroup:
                GroupView(showInspector: $showInspector)
                    .environmentObject(clickedGroup)
            case .editTask:
                TaskEditView(showInspector: $showInspector)
                    .environmentObject(clickedTask)
                    .padding()
            case .addShortcut:
                AddShortcutView(showInspector: $showInspector)
            case .editShortcut:
                EditShortcutView(showInspector: $showInspector)
                    .environmentObject(clickedShortcut)
            }
        }
        .onAppear {
            navSelection = defaultView
        }
    }
}

#Preview {
    MacContentView(tasksCount: .constant(5), showExportCSV: .constant(false))
}
