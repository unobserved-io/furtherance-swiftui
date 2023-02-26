//
//  Autosave.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Foundation
import SwiftUI

class Autosave: ObservableObject {
    private let autosaveUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Furtherance/autosave.txt")
    @Published var showAlert = false
    
    func write() {
        let timerHelper = TimerHelper.sharedInstance
        let convertedStart = convertToRFC3339(dateIn: timerHelper.startTime)
        let convertedStop = convertToRFC3339(dateIn: Date.now)
        
        let text = "\(timerHelper.taskName)$FUR$\(convertedStart)$FUR$\(convertedStop)$FUR$\(timerHelper.taskTags)"
        
        do {
            try text.write(to: autosaveUrl, atomically: false, encoding: .utf8)
        }
        catch {
            print("Error writing autosave: \(error)")
        }
    }
    
    func read(viewContext: NSManagedObjectContext) {
        do {
            let input = try String(contentsOf: autosaveUrl, encoding: .utf8)
            let inputSplit = input.components(separatedBy: "$FUR$")
            let convertedStart = convertFromRFC3339(dateIn: inputSplit[1])
            let convertedStop = convertFromRFC3339(dateIn: inputSplit[2])
            
            let task = FurTask(context: viewContext)
            task.id = UUID()
            task.name = inputSplit[0]
            task.startTime = convertedStart
            task.stopTime = convertedStop
            task.tags = inputSplit[3]
            do {
                try viewContext.save()
            } catch {
                print("Error writing autosave: \(error)")
            }
            delete()
        }
        catch {
            print("Error reading autosave: \(error)")
        }
    }
    
    func exists() -> Bool {
        return FileManager.default.fileExists(atPath: autosaveUrl.path)
    }
    
    func asAlert() {
        showAlert.toggle()
    }
    
    func delete() {
        if exists() {
            do {
                // Delete file
                try FileManager.default.removeItem(atPath: autosaveUrl.path)
            }
            catch {
                print("Error deleting autosave \(error)")
            }
        }
    }
    
    private func convertFromRFC3339(dateIn: String) -> Date {
        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.timeZone = TimeZone.current
        iso8601DateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        return iso8601DateFormatter.date(from: dateIn) ?? Date.now
    }
    
    private func convertToRFC3339(dateIn: Date) -> String {
        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        iso8601DateFormatter.timeZone = TimeZone.current
        return iso8601DateFormatter.string(from: dateIn)
    }
}
