//
//  FurtheranceApp.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

@main
struct FurtheranceApp: App {
    let persistenceController = PersistenceController.shared

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true

    @ObservedObject var storeModel = StoreModel.shared

    @State private var navigator = Navigator.shared
    @State private var showDeleteDialog = false
    @State private var showProAlert = false
    @State private var dialogTitle = ""
    @State private var dialogMessage = ""
    @State private var confirmBtn = ""
    @State private var addTaskSheet = false
    @State private var showImportCSV = false
    @State private var showInvalidCSVAlert = false
    @State(initialValue: 0) var tasksCount: Int
    @State(initialValue: false) var showExportCSV: Bool

    init() {
        launchCount += 1
    }

    var body: some Scene {
        WindowGroup {
            mainContentView
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    #if os(macOS)
                    NSWindow.allowsAutomaticWindowTabbing = false
                    #endif
                    Task {
                        try await storeModel.fetchProducts()
                    }
                }
                .confirmationDialog(dialogTitle, isPresented: $showDeleteDialog) {
                    Button(confirmBtn, role: .destructive) {
                        if confirmBtn == "Delete" {
                            deleteAllTasks()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(dialogMessage)
                }
                .sheet(isPresented: $addTaskSheet) {
                    AddTaskView().environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
                .alert("Upgrade to Pro", isPresented: $showProAlert) {
                    Button("Cancel") {}
                    if let product = storeModel.products.first {
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
                    }
                } message: {
                    Text("That feature is only available in Furtherance Pro.")
                }
                .fileImporter(isPresented: $showImportCSV, allowedContentTypes: [UTType.commaSeparatedText]) { result in
                    do {
                        let fileURL = try result.get()
                        if fileURL.startAccessingSecurityScopedResource() {
                            let data = try String(contentsOf: fileURL)
                            // Split string into rows
                            var rows = data.components(separatedBy: "\n")
                            // Remove headers
                            if rows[0] == "Name,Tags,Start Time,Stop Time,Total Seconds" {
                                rows.removeFirst()

                                // Split rows into columns
                                var furTasks = [FurTask]()
                                for row in rows {
                                    let columns = row.components(separatedBy: ",")

                                    if columns.count == 5 {
                                        let task = FurTask(context: persistenceController.container.viewContext)
                                        task.id = UUID()
                                        task.name = columns[0]
                                        task.tags = columns[1]
                                        task.startTime = localDateTimeFormatter.date(from: columns[2])
                                        task.stopTime = localDateTimeFormatter.date(from: columns[3])
                                        furTasks.append(task)
                                    }
                                }
                                try? persistenceController.container.viewContext.save()
                            } else {
                                showInvalidCSVAlert.toggle()
                            }
                        }
                        fileURL.stopAccessingSecurityScopedResource()
                    } catch {
                        print("Failed to import data: \(error.localizedDescription)")
                    }
                }
                .alert("Invalid CSV", isPresented: $showInvalidCSVAlert) {
                    Button("OK") {}
                } message: {
                    Text("The CSV you chose is not a valid Furtherance CSV.")
                }
        }
        .commands {
            CommandMenu("Database") {
                Button("Export as CSV") {
                    if storeModel.purchasedIds.isEmpty {
                        showProAlert.toggle()
                    } else {
                        showExportCSV.toggle()
                    }
                }
                .badge(storeModel.purchasedIds.isEmpty ? "Pro" : nil)
                .disabled(tasksCount == 0)
                Button("Import CSV") {
                    if storeModel.purchasedIds.isEmpty {
                        showProAlert.toggle()
                    } else {
                        showImportCSV.toggle()
                    }
                }
                .badge(storeModel.purchasedIds.isEmpty ? "Pro" : nil)
                .disabled(tasksCount == 0)
                Button("Delete All") {
                    if showDeleteConfirmation {
                        showDeleteDialog = true
                        dialogTitle = "Delete all data?"
                        dialogMessage = "This will delete all of your saved tasks."
                        confirmBtn = "Delete"
                    } else {
                        deleteAllTasks()
                    }
                }
                .disabled(tasksCount == 0)
            }
            #if os(macOS)
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}
            CommandGroup(replacing: CommandGroupPlacement.windowList) {}
            CommandGroup(replacing: CommandGroupPlacement.windowArrangement) {}
            CommandGroup(replacing: CommandGroupPlacement.singleWindowList) {}
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Reports") {
                    if storeModel.purchasedIds.isEmpty {
                        showProAlert.toggle()
                    } else {
                        navigator.openView(.reports)
                    }
                }
                .badge(storeModel.purchasedIds.isEmpty ? "Pro" : nil)
                .keyboardShortcut("R", modifiers: EventModifiers.command)
            }
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Add Task") {
                    addTaskSheet.toggle()
                }
            }
            #endif
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .defaultSize(width: 400, height: 450)
        #endif
    }
    
    private var mainContentView: some View {
        #if os(macOS)
            MacContentView(tasksCount: $tasksCount, showExportCSV: $showExportCSV)
        #else
            TimerView(tasksCount: $tasksCount, showExportCSV: $showExportCSV)
        #endif
    }
}
