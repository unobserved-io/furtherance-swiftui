//
//  StartFurtheranceTimer.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 27/1/24.
//

//import Foundation
//import AppIntents
//import SwiftData
//
//struct StartFurtheranceTimer: AppIntent {
//    static var title: LocalizedStringResource = "Start Furtherance Timer"
//    
//    @Parameter(title: "Task")
//    var task: String
//   @Parameter(title: "#tags")
//   var tags: String?
//    
//    @MainActor
//    func perform() async throws -> some IntentResult {
//        if tags?.isEmpty ?? true {
//            TaskTagsInput.sharedInstance.text = task
//        } else {
//            TaskTagsInput.sharedInstance.text = "\(task) \(tags!)"
//        }
//        let modelContext = ModelContext(PersistentTimer.container)
//        if let persistentTimer = try? modelContext.fetch(FetchDescriptor<PersistentTimer>()) {
//            if TaskTagsInput.sharedInstance.text.trimmingCharacters(in: .whitespaces).first != "#" {
//                StopWatchHelper.shared.start()
//                TimerHelper.shared.onStart(nameAndTags: TaskTagsInput.sharedInstance.text)
//                #if os(iOS)
//                if persistentTimer.first == nil {
//                    let newPersistentTimer = PersistentTimer()
//                    newPersistentTimer.isRunning = true
//                    newPersistentTimer.startTime = TimerHelper.shared.startTime
//                    newPersistentTimer.taskName = TimerHelper.shared.taskName
//                    newPersistentTimer.taskTags = TimerHelper.shared.taskTags
//                    newPersistentTimer.nameAndTags = TimerHelper.shared.nameAndTags
//                    modelContext.insert(newPersistentTimer)
//                } else {
//                    persistentTimer.first?.isRunning = true
//                    persistentTimer.first?.startTime = TimerHelper.shared.startTime
//                    persistentTimer.first?.taskName = TimerHelper.shared.taskName
//                    persistentTimer.first?.taskTags = TimerHelper.shared.taskTags
//                    persistentTimer.first?.nameAndTags = TimerHelper.shared.nameAndTags
//                }
//                #endif
//            }
//        }
//        print("Ran! \(task)")
//        return .result()
//    }
//    
//    static var parameterSummary: some ParameterSummary {
//        Summary("Start Furtherance timer with task \(\.$task) and tags \(\.$tags)")
//    }
//}

