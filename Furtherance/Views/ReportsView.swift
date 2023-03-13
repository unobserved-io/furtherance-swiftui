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
    private enum FilterBy {
        case none
        case task
        case tags
    }
    
    @State private var timeframe: Timeframe = .thirtyDays
    @State private var sortByTask: Bool = true
    @State private var filterBy: FilterBy = .none
    @State private var filter: Bool = false
    @State private var exactMatch: Bool = false
    @State private var filterInput: String = ""
    
    var body: some View {
        VStack(spacing: 5) {
            VStack(alignment: .leading) {
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

                HStack {
                    Picker("Filter by:", selection: $filterBy) {
                        Text("None").tag(FilterBy.none)
                        Text("Task").tag(FilterBy.task)
                        Text("Tag").tag(FilterBy.tags)
                    }
                    TextField("", text: $filterInput)
                        .disabled(filterBy == .none)
                }
                
                Toggle(isOn: $exactMatch) {
                    Text("Exact match")
                }
            }
            .padding()
            
            Divider().padding(.bottom)
            
            Text("Total time: \(formatTimeLong(getTotalTime()))").bold()
            
            if sortByTask {
                List {
                    ForEach(sortedByTask()) { reportedTask in
                        Section(header: sectionHeader(heading: reportedTask.heading, totalSeconds: reportedTask.totalSeconds)) {
                            ForEach(Array(reportedTask.tags), id: \.0) { tagKey, tagInt in
                                HStack {
                                    Text(tagKey)
                                    Spacer()
                                    Text(formatTimeLong(tagInt))
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                            }
                        }
                    }
                }
                    
            } else {
                // Sorted by tag
                List {
                    ForEach(sortedByTag()) { reportedTag in
                        Section(header: sectionHeader(heading: reportedTag.heading, totalSeconds: reportedTag.totalSeconds)) {
                            ForEach(reportedTag.taskNames, id:\.0) { taskKey, taskInt in
                                HStack {
                                    Text(taskKey)
                                    Spacer()
                                    Text(formatTimeLong(taskInt))
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 360, idealWidth: 400, minHeight: 170, idealHeight: 600)
    }
    
    private func sortedByTask() -> [ReportByTask] {
        var uniqueList: [ReportByTask] = []
        
        for task in allTasks {
            var match = false
            
            if filterBy == .task && !filterInput.isEmpty {
                if exactMatch {
                    if task.name?.lowercased() == filterInput.lowercased() {
                        match = true
                    }
                } else {
                    if task.name?.lowercased().contains(filterInput.lowercased()) ?? false {
                        match = true
                    }
                }
            } else if filterBy == .tags && !filterInput.isEmpty {
                // TODO: Breakdown tags to see if they match one of the filter input
                if exactMatch {
                    if task.tags == filterInput.lowercased() {
                        match = true
                    }
                } else {
                    if task.tags?.contains(filterInput.lowercased()) ?? false {
                        match = true
                    }
                }
            } else {
                match = true
            }
            
            if match {
                let index = uniqueList.firstIndex { $0.heading == task.name }
                if index != nil {
                    // Task was found
                    uniqueList[index!].addTask(task)
                } else {
                    // Task not found
                    uniqueList.append(ReportByTask(task))
                }
            }
        }
        
        return uniqueList
    }
    
    private func sortedByTag() -> [ReportByTags] {
        var uniqueList: [ReportByTags] = []
        
        for task in allTasks {
            var match = false
            
            if filterBy == .task && !filterInput.isEmpty {
                if exactMatch {
                    if task.name?.lowercased() == filterInput.lowercased() {
                        match = true
                    }
                } else {
                    if task.name?.lowercased().contains(filterInput.lowercased()) ?? false {
                        match = true
                    }
                }
            } else if filterBy == .tags && !filterInput.isEmpty {
                // TODO: Breakdown tags to see if they match one of the filter input
                if exactMatch {
                    if task.tags == filterInput.lowercased() {
                        match = true
                    }
                } else {
                    if task.tags?.contains(filterInput.lowercased()) ?? false {
                        match = true
                    }
                }
            } else {
                match = true
            }
            
            if match {
                let index = uniqueList.firstIndex { $0.heading == task.tags }
                if index != nil {
                    // Task was found
                    uniqueList[index!].addTask(task)
                } else {
                    // Task not found
                    uniqueList.append(ReportByTags(task))
                }
            }
        }
        
        return uniqueList
    }
    
    private func getTotalTime() -> Int {
        var totalTaskTime = 0
        for task in allTasks {
            totalTaskTime += (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
        return totalTaskTime
    }
    
    private func taskAndTime(_ reportByTask: ReportByTask) -> some View {
        return HStack {
            Text(reportByTask.heading)
            Spacer()
            Text(formatTimeLong(reportByTask.totalSeconds))
        }
    }
    
    private func tagAndTime(_ reportByTags: ReportByTags) -> some View {
        return HStack {
            Text(reportByTags.heading)
            Spacer()
            Text(formatTimeLong(reportByTags.totalSeconds))
        }
    }
    
    private func sectionHeader(heading: String, totalSeconds: Int) -> some View{
        return HStack {
            Text(heading)
            Spacer()
            Text(formatTimeLong(totalSeconds))
        }
    }
}

struct ReportByTask: Identifiable {
    var id = UUID()
    let heading: String
    var totalSeconds: Int = 0
    var tags: [(String, Int)] = []
    
    init(_ task: FurTask) {
        heading = task.name ?? "Unknown"
        addTask(task)
    }
    
    mutating func addTask(_ task: FurTask) {
        // add total time to total seconds
        totalSeconds = totalSeconds + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        // check if tags contains tags. Either way, add time
        var unwrappedTags = "No tags"
        if !(task.tags?.isEmpty ?? true) {
            unwrappedTags = task.tags ?? "No tags"
        }
        
        let index = tags.firstIndex { $0.0 == unwrappedTags }
        if index != nil {
            tags[index!].1 += (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        } else {
            tags.append((unwrappedTags, Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0))
        }
    }
}

struct ReportByTags: Identifiable {
    var id = UUID()
    let heading: String
    var totalSeconds: Int = 0
    var taskNames: [(String, Int)] = []
    
    init(_ task: FurTask) {
        heading = task.tags ?? "Unknown"
        addTask(task)
    }
    
    mutating func addTask(_ task: FurTask) {
        // add total time to total seconds
        totalSeconds = totalSeconds + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)

        // check if tags contains tags. Either way, add time
        let index = taskNames.firstIndex { $0.0 == task.name }
        if index != nil {
            taskNames[index!].1 += (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        } else {
            taskNames.append((task.name ?? "Unknown", Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0))
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
    }
}
