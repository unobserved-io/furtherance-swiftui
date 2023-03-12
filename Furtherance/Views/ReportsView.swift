//
//  ReportsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/12/23.
//

import SwiftUI

struct ReportsView: View {
    @FetchRequest(
        entity: FurTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        animation: .default
    )
    var allTasks: FetchedResults<FurTask>
    private enum Timeframe {
        case week
        case month
        case thirtyDays
        case oneEightyDays
        case year
        case custom
    }
    
    @State private var timeframe: Timeframe = .thirtyDays
    @State private var sortByTask: Bool = true
    @State private var filterByTask: Bool = true
    @State private var filter: Bool = true
    @State private var filterInput: String = ""
    
    var body: some View {
        List {
            Section {
                Picker("Timeframe", selection: $timeframe) {
                    Text("Past week").tag(Timeframe.week)
                    Text("This month").tag(Timeframe.month)
                    Text("Past 30 days").tag(Timeframe.thirtyDays)
                    Text("Past 180 days").tag(Timeframe.oneEightyDays)
                    Text("Past year").tag(Timeframe.year)
                    Text("Date range").tag(Timeframe.custom)
                }
                
                Picker("Sort by", selection: $sortByTask) {
                    Text("Task").tag(true)
                    Text("Tag").tag(false)
                }
                .pickerStyle(.segmented)
                
                Toggle("Filter", isOn: $filter)
                    .toggleStyle(.switch)
                
                if filter {
                    HStack {
                        Picker("", selection: $filterByTask) {
                            Text("Task").tag(true)
                            Text("Tag").tag(false)
                        }
                        TextField("", text: $filterInput)
                    }
                }
                
                Button("Refresh") {
                    sortedByTask()
                }
            }
            
            Section {
                Text("Total time: 9:29:48")
                // TODO: ForEach that is expandable
                if sortByTask {
                    // Sorted by task
                } else {
                    // Sorted by tag
                }
            }
        }
    }
    
    private func sortedByTask() {
//        var uniqueList: [String: [FurTask]] = [:]
//        var uniqueTaskNames: [String] = []
//        var reportsByTask: [ReportByTask] = []
        var uniqueList: [String: ReportByTask] = [:]
        
        for task in allTasks {
            if uniqueList.keys.contains(task.name ?? "Unknown") {
                uniqueList[task.name ?? "Unknown"]?.addTask(task)
            } else {
//                uniqueTaskNames.append(task.name ?? "Unknown")
//                uniqueList[task.name ?? "Unknown"]?.append(task)
                uniqueList[task.name ?? "Unknown"] = ReportByTask(task)
            }
        }
    }
}

struct ReportByTask {
    @State var totalSeconds: Int = 0
    @State var tags: [String: Int] = [:]
    
    init(_ task: FurTask) {
        addTask(task)
    }
    
    func addTask(_ task: FurTask) {
        // add total time to total seconds
        totalSeconds += (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        // check if tags contains tags. Either way, add time
        if task.tags != nil && !(task.tags?.isEmpty ?? true) {
            tags[task.tags!] = (tags[task.tags!] ?? 0) + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
    }
}
