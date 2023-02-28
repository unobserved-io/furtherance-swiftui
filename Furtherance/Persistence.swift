//
//  Persistence.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0 ..< 10 {
            let newItem = FurTask(context: viewContext)
            newItem.startTime = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error during save \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Furtherance")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // CloudKit history and update handling
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to initialize persistent container")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                print("Unresolved data error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
