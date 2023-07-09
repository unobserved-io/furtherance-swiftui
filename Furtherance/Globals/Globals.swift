//
//  Globals.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/12/23.
//

import SwiftUI
import CoreData

let localDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

func formatTimeShort(_ totalSeconds: Int) -> String {
    /// Format input seconds into a time format that does not include hours if there isn't any, and doesn't pad the hours
    let hours = totalSeconds / 3600
    let hoursString = String(hours)
    let minutes = (totalSeconds % 3600) / 60
    let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
    let seconds = totalSeconds % 60
    let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
    if hours > 0 {
        return hoursString + ":" + minutesString + ":" + secondsString
    } else {
        return minutesString + ":" + secondsString
    }
}

func formatTimeLong(_ totalSeconds: Int) -> String {
    /// Format input seconds into a time format that includes padded hours
    let hours = totalSeconds / 3600
    let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
    let minutes = (totalSeconds % 3600) / 60
    let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
    let seconds = totalSeconds % 60
    let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
    return hoursString + ":" + minutesString + ":" + secondsString
}

func formatTimeLongWithoutSeconds(_ totalSeconds: Int) -> String {
    /// Format input seconds into a time format that does not include hours if there isn't any, and doesn't pad the hours
    let hours = totalSeconds / 3600
    let hoursString = String(hours)
    let minutes = (totalSeconds % 3600) / 60
    let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
    if minutes < 1 {
        return "< 0:01"
    } else {
        return hoursString + ":" + minutesString
    }
}

func deleteAllTasks() {
    do {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult>
        fetchRequest = NSFetchRequest(entityName: "FurTask")
        
        let deleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest
        )
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let batchDelete = try PersistenceController.shared.container.viewContext.execute(deleteRequest)
            as? NSBatchDeleteResult
        
        guard let deleteResult = batchDelete?.result
            as? [NSManagedObjectID]
        else { return }
        
        let deletedObjects: [AnyHashable: Any] = [
            NSDeletedObjectsKey: deleteResult
        ]
        
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: deletedObjects,
            into: [PersistenceController.shared.container.viewContext]
        )
    } catch {
        print("Error deleting all tasks: \(error)")
    }
}
