//
//  ReportView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 22.07.2024.
//

import SwiftUI

struct ReportView: View {
    @FetchRequest(
        entity: FurTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        predicate: NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", (Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: Date.now)) ?? Date.now) as NSDate, Date.now as NSDate),
        animation: .default
    )
    var allTasks: FetchedResults<FurTask>
    private enum Timeframe {
        case thisWeek
        case lastWeek
        case past7Days
        case thisMonth
        case lastMonth
        case thirtyDays
        case oneEightyDays
        case year
        case allTime
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
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date.now.startOfDay) ?? Date.now
    @State private var customStopDate: Date = .now.endOfDay
    private var allListedTime: Int = 0
    
    var body: some View {
        VStack(spacing: 5) {
            VStack(alignment: .leading) {
                Picker("Timeframe", selection: $timeframe) {
                    Text("This week").tag(Timeframe.thisWeek)
                    Text("Last week").tag(Timeframe.lastWeek)
                    Text("Past 7 days").tag(Timeframe.past7Days)
                    Text("This month").tag(Timeframe.thisMonth)
                    Text("Last month").tag(Timeframe.lastMonth)
                    Text("Past 30 days").tag(Timeframe.thirtyDays)
                    Text("Past 180 days").tag(Timeframe.oneEightyDays)
                    Text("Past year").tag(Timeframe.year)
                    Text("All time").tag(Timeframe.allTime)
                    Text("Date range").tag(Timeframe.custom)
                }
                .onChange(of: timeframe) { _, newTimeframe in
                    var newStartDate = Calendar.current.startOfDay(for: Date.now)
                    var newStopDate = Date.now
                    switch newTimeframe {
                    case .thisWeek:
                        newStartDate = newStartDate.startOfWeek
                    case .lastWeek:
                        newStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: (Calendar.current.date(byAdding: .weekOfYear, value: -1, to: newStartDate) ?? Date.now)).date ?? Date.now
                        newStopDate = newStartDate.endOfWeek
                    case .past7Days:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -6, to: newStartDate) ?? Date.now
                    case .thisMonth:
                        newStartDate = Date.now.startOfMonth
                    case .lastMonth:
                        let endOfLastMonth = Calendar.current.date(byAdding: .day, value: -1, to: Date.now.startOfMonth) ?? Date.now
                        newStartDate = endOfLastMonth.startOfMonth
                        newStopDate = newStartDate.endOfMonth
                    case .thirtyDays:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -29, to: newStartDate) ?? Date.now
                    case .oneEightyDays:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -179, to: newStartDate) ?? Date.now
                    case .year:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -364, to: newStartDate) ?? Date.now
                    case .allTime:
                        newStartDate = Date(timeIntervalSince1970: 0)
                    case .custom:
                        newStartDate = customStartDate
                        newStopDate = customStopDate
                    }
                    allTasks.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", newStartDate as NSDate, newStopDate as NSDate)
                }
                
                if timeframe == .custom {
                    HStack {
                        DatePicker(
                            selection: $customStartDate,
                            in: Date(timeIntervalSinceReferenceDate: 0) ... customStopDate,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .labelsHidden()
                        .onChange(of: customStartDate) { _, newStartDate in
                            customStartDate = newStartDate.startOfDay
                            allTasks.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", customStartDate as NSDate, customStopDate as NSDate)
                        }
                        Text("to")
                        DatePicker(
                            selection: $customStopDate,
                            in: customStartDate ... Date.now.endOfDay,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .frame(minHeight: 35)
                        .labelsHidden()
                        .onChange(of: customStopDate) { _, newStopDate in
                            customStopDate = newStopDate.endOfDay
                            allTasks.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", customStartDate as NSDate, customStopDate as NSDate)
                        }
                    }
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
                    TextField("", text: Binding(
                        get: { filterInput },
                        set: { newValue in
                            if filterBy == .task {
                                filterInput = newValue.trimmingCharacters(in: ["#"])
                            } else {
                                filterInput = newValue
                            }
                        }
                    ))
                        .disabled(filterBy == .none)
                }
                
                Toggle(isOn: $exactMatch) {
                    Text("Exact match")
                }
                .disabled(filterBy == .none)
            }
            .padding()
            
            Divider().padding(.bottom)
            
            Text("Total time:   \(formatTimeLong(getTotalTime()))")
                .font(Font.monospacedDigit(.system(.body))())
                .bold()
            
            if sortByTask {
                List {
                    ForEach(sortedByTask()) { reportedTask in
                        Section(header: sectionHeader(heading: reportedTask.heading, totalSeconds: reportedTask.totalSeconds)) {
                            ForEach(Array(reportedTask.tags), id: \.0) { tagKey, tagInt in
                                HStack {
                                    Text(tagKey)
                                    Spacer()
                                    Text(formatTimeLong(tagInt))
                                        .font(Font.monospacedDigit(.system(.body))())
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
                                        .font(Font.monospacedDigit(.system(.body))())
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
                // Breakdown tags to see if they match one of the filter input
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
                // Breakdown tags to see if they match one of the filter input
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
                // Breakdown tags to see if they match one of the filter input
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
                totalTaskTime += (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
            }
        }
        return totalTaskTime
    }
    
    private func sectionHeader(heading: String, totalSeconds: Int) -> some View{
        return HStack {
            Text(heading)
            Spacer()
            Text(formatTimeLong(totalSeconds))
                .font(Font.monospacedDigit(.system(.body))())
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
        if task.tags?.isEmpty ?? true {
            heading = "No tags"
        } else {
            heading = task.tags ?? "No tags"
        }
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

#Preview {
    ReportView()
}
