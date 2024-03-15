//
//  MacHistoryList.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI

struct MacHistoryList: View {
    @EnvironmentObject var clickedGroup: ClickedGroup
    @EnvironmentObject var clickedTask: ClickedTask
    
    @Binding var showInspector: Bool
    @Binding var typeToEdit: EditInInspector
    
    @AppStorage("limitHistory") private var limitHistory = true
    @AppStorage("historyListLimit") private var historyListLimit = 10
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("totalInclusive") private var totalInclusive = false
    @AppStorage("showSeconds") private var showSeconds = true
    
    @SectionedFetchRequest(
        sectionIdentifier: \.startDateRelative,
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        animation: .default
    )
    var tasksByDay: SectionedFetchResults<String, FurTask>
    
    @State private var stopWatchHelper = StopWatchHelper.shared
    @State private var addTaskSheet = false
    
    var body: some View {
        NavigationStack {
            if tasksByDay.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "fossil.shell",
                    description: Text("Completed tasks will appear here.")
                )
            } else {
                ScrollView {
                    Form {
                        if limitHistory {
                            if tasksByDay.count > historyListLimit {
                                ForEach(0 ..< historyListLimit, id: \.self) { index in
                                    showHistoryList(tasksByDay[index])
                                }
                            } else {
                                ForEach(0 ..< tasksByDay.count, id: \.self) { index in
                                    showHistoryList(tasksByDay[index])
                                }
                            }
                        } else {
                            ForEach(tasksByDay) { section in
                                showHistoryList(section)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button { addTaskSheet.toggle() } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
            
            if !showInspector {
                ToolbarItem {
                    Button {
                        showInspector = true
                    } label: {
                        Image(systemName: "sidebar.trailing")
                    }
                }
            }
        }
        .sheet(isPresented: $addTaskSheet) {
            AddTaskView()
        }
    }
    
    private func showHistoryList(_ section: SectionedFetchResults<String, FurTask>.Section) -> some View {
        return Section(header: sectionHeader(section)) {
            ForEach(sortTasks(section)) { taskGroup in
                TaskRow(taskGroup: taskGroup)
                    .padding(.bottom, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if taskGroup.tasks.count > 1 {
                            clickedGroup.taskGroup = taskGroup
                            typeToEdit = .group
                            showInspector.toggle()
                        } else {
                            clickedTask.task = taskGroup.tasks.first!
                            typeToEdit = .single
                            showInspector.toggle()
                        }
                    }
                    .disabled(stopWatchHelper.isRunning)
            }
        }
    }
    
    private func sectionHeader(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> some View {
        return HStack {
            Text(taskSection.id.localizedCapitalized)
            Spacer()
            if showDailySum {
                if taskSection.id == "today", totalInclusive {
                    if stopWatchHelper.isRunning {
                        let adjustedStartTime = Calendar.current.date(byAdding: .second, value: -totalSectionTime(taskSection), to: stopWatchHelper.startTime)
                        Text(
                            timerInterval: (adjustedStartTime ?? .now) ... stopWatchHelper.stopTime,
                            countsDown: false
                        )
                    } else {
                        Text(totalSectionTimeFormatted(taskSection))
                    }
                } else {
                    Text(totalSectionTimeFormatted(taskSection))
                }
            }
        }
        .font(.headline)
        .padding(.top).padding(.bottom)
    }
    
    private func sortTasks(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> [FurTaskGroup] {
        var newGroups = [FurTaskGroup]()
        for task in taskSection {
            var foundGroup = false
            
            for taskGroup in newGroups {
                if taskGroup.name == task.name && taskGroup.tags == task.tags {
                    taskGroup.add(task: task)
                    foundGroup = true
                }
            }
            if !foundGroup {
                newGroups.append(FurTaskGroup(task: task))
            }
        }
        return newGroups
    }
    
    private func totalSectionTime(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> Int {
        var totalTime = 0
        for task in taskSection {
            totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
        return totalTime
    }
    
    private func totalSectionTimeFormatted(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> String {
        let totalTime: Int = totalSectionTime(taskSection)
        if showSeconds {
            return formatTimeShort(totalTime)
        } else {
            return formatTimeLongWithoutSeconds(totalTime)
        }
    }
}

#Preview {
    MacHistoryList(showInspector: .constant(false), typeToEdit: .constant(EditInInspector.single))
}
