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
    let contentView = ContentView.sharedInstance
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showDialog = false
    @State private var backupFailed = false
    @State private var importFailed = false
    @State private var backupSucceeded = false
    @State private var dialogTitle = ""
    @State private var dialogMessage = ""
    @State private var confirmBtn = ""

    var body: some Scene {
        WindowGroup {
            contentView
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
                // Backup failed alert
                .alert("Backup Failed", isPresented: $backupFailed) {
                    Button("OK") {}
                } message: {
                    Text("A backup was not created.")
                }
                // Backup succeeded alert
                .alert("Backup Succeeded", isPresented: $backupSucceeded) {
                    Button("OK") {}
                } message: {
                    let backUpFolderUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let backupUrl = backUpFolderUrl.appendingPathComponent("FurtheranceBackup.sqlite")
                    Text("A backup was created at \(backupUrl.path())")
                }
                // Import failed alert
                .alert("Import Failed", isPresented: $backupSucceeded) {
                    Button("OK") {}
                } message: {
                    let backUpFolderUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let backupUrl = backUpFolderUrl.appendingPathComponent("FurtheranceBackup.sqlite")
                    Text("Please make sure your Furtherance backup is located at \(backupUrl.path())")
                }
                .confirmationDialog(dialogTitle, isPresented: $showDialog) {
                    Button(confirmBtn, role: .destructive) {
                        if confirmBtn == "Delete" {
                            // TODO: Remove taskCount test when disabled Delete All works
                            var taskCount = 0
                            do {
                                taskCount = try persistenceController.container.viewContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "FurTask"))
                            } catch {
                                print("Error checking for empty tasks: \(error)")
                            }
                            if taskCount != 0 {
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
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(dialogMessage)
                }
        }
        .commands {
            CommandMenu("Database") {
                Button("Delete All") {
                    showDialog = true
                    dialogTitle = "Delete all data?"
                    dialogMessage = "This will delete all of your saved tasks."
                    confirmBtn = "Delete"
                }
                // TODO: Disable when task list is empty
//                .disabled()
            }
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}
            CommandGroup(replacing: CommandGroupPlacement.windowList) {}
            CommandGroup(replacing: CommandGroupPlacement.windowArrangement) {}
            CommandGroup(replacing: CommandGroupPlacement.singleWindowList) {}
        }
        .defaultSize(width: 360, height: 600)
        
#if os(macOS)
        Settings {
            SettingsView()
        }
        .defaultSize(width: 400, height: 450)
#endif
    }
}
