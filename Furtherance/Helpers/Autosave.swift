//
//  Autosave.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import CoreData
import Foundation
import SwiftUI

@MainActor
class Autosave: ObservableObject {
    @Published var showAlert = false
    
    func getAutosaveUrl() async throws -> URL {
        if let autosaveUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return autosaveUrl.appendingPathComponent("autosave.txt")
        } else {
            throw RuntimeError("Cannot open Autosave")
        }
    }
    
    func write() async {
        let timerHelper = TimerHelper.shared
        let convertedStart = convertToRFC3339(dateIn: timerHelper.startTime)
        let convertedStop = convertToRFC3339(dateIn: Date.now)
        
        let text = "\(timerHelper.taskName)$FUR$\(convertedStart)$FUR$\(convertedStop)$FUR$\(timerHelper.taskTags)"
        
        do {
            try text.write(to: await getAutosaveUrl(), atomically: false, encoding: .utf8)
        }
        catch {
            print("Error writing autosave: \(error)")
        }
    }
    
    func read(viewContext: NSManagedObjectContext) async {
        do {
            let input = try String(contentsOf: await getAutosaveUrl(), encoding: .utf8)
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
            }
            catch {
                print("Error writing autosave: \(error)")
            }
            await delete()
        }
        catch {
            print("Error reading autosave: \(error)")
        }
    }
    
    func exists() async -> Bool {
        do {
            return try FileManager.default.fileExists(atPath: await getAutosaveUrl().path)
        } catch {
            print("Could not find autosave: \(error)")
            return false
        }
    }
    
    func asAlert() {
        showAlert.toggle()
    }
    
    func delete() async {
        if await exists() {
            do {
                // Delete file
                try FileManager.default.removeItem(atPath: await getAutosaveUrl().path)
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
