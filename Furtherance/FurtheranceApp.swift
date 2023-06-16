//
//  FurtheranceApp.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct FurtheranceApp: App {
    let persistenceController = PersistenceController.shared
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("launchCount") private var launchCount = 0
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @ObservedObject var stopWatch = StopWatch.sharedInstance
    @State private var showDeleteDialog = false
    @State private var showExportCSV = false
    @State private var showProAlert = false
    @State private var dialogTitle = ""
    @State private var dialogMessage = ""
    @State private var confirmBtn = ""
    @State private var addTaskSheet = false
    @State(initialValue: 0) var tasksCount: Int
    @State(initialValue: []) var navPath: [String]
    
    init() {
        launchCount += 1
    }

    var body: some Scene {
        WindowGroup {
            ContentView(tasksCount: $tasksCount, navPath: $navPath)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    Task {
                        try await storeModel.fetchProducts()
                    }
                }
                .confirmationDialog(dialogTitle, isPresented: $showDeleteDialog) {
                    Button(confirmBtn, role: .destructive) {
                        if confirmBtn == "Delete" {
                            do {
                                let fetchRequest: NSFetchRequest<NSFetchRequestResult>
                                fetchRequest = NSFetchRequest(entityName: "FurTask")
                                
                                let deleteRequest = NSBatchDeleteRequest(
                                    fetchRequest: fetchRequest
                                )
                                deleteRequest.resultType = .resultTypeObjectIDs
                                
                                let batchDelete = try persistenceController.container.viewContext.execute(deleteRequest)
                                    as? NSBatchDeleteResult
                                
                                guard let deleteResult = batchDelete?.result
                                    as? [NSManagedObjectID]
                                else { return }
                                
                                let deletedObjects: [AnyHashable: Any] = [
                                    NSDeletedObjectsKey: deleteResult
                                ]
                                
                                NSManagedObjectContext.mergeChanges(
                                    fromRemoteContextSave: deletedObjects,
                                    into: [persistenceController.container.viewContext]
                                )
                            } catch {
                                print("Error deleting all tasks: \(error)")
                            }
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
                .fileExporter(
                    isPresented: $showExportCSV,
                    document: CSVFile(initialText: getDataAsCSV()),
                    contentType: UTType.commaSeparatedText,
                    defaultFilename: "Furtherance.csv"
                ) { _ in }
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
                .disabled(tasksCount == 0 || stopWatch.isRunning)
                Button("Delete All") {
                    showDeleteDialog = true
                    dialogTitle = "Delete all data?"
                    dialogMessage = "This will delete all of your saved tasks."
                    confirmBtn = "Delete"
                }
                .disabled(tasksCount == 0 || stopWatch.isRunning)
            }
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}
            CommandGroup(replacing: CommandGroupPlacement.windowList) {}
            CommandGroup(replacing: CommandGroupPlacement.windowArrangement) {}
            CommandGroup(replacing: CommandGroupPlacement.singleWindowList) {}
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Reports") {
                    if storeModel.purchasedIds.isEmpty {
                        showProAlert.toggle()
                    } else {
                        navPath.append("reports")
                    }
                }
                .keyboardShortcut("R", modifiers: EventModifiers.command)
                .disabled(stopWatch.isRunning)
            }
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Add Task") {
                    addTaskSheet.toggle()
                }
                .disabled(stopWatch.isRunning)
            }
        }
        .defaultSize(width: 360, height: 600)
        
#if os(macOS)
        Settings {
            SettingsView()
        }
        .defaultSize(width: 400, height: 450)
#endif
    }
    
    private func getDataAsCSV() -> String {
        let fetchRequest: NSFetchRequest<FurTask> = FurTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)]
        var allData: [FurTask] = []
        do {
            allData = try persistenceController.container.viewContext.fetch(fetchRequest)
        } catch {
            print(error)
        }
        var csvString = "Name,Tags,Start Time,Stop Time,Total Seconds\n"
        
        allData.forEach() { task in
            let totalSeconds = task.stopTime?.timeIntervalSince(task.startTime ?? Date.now)
            let localDateFormatter = DateFormatter()
            localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let startString = localDateFormatter.string(from: task.startTime ?? Date.now)
            let stopString = localDateFormatter.string(from: task.stopTime ?? Date.now)
            csvString += "\(task.name ?? "Unknown"),\(task.tags ?? ""),\(startString),\(stopString),\(Int(totalSeconds ?? 0))\n"
        }
        
        return csvString
    }
}
