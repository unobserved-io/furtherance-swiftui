//
//  MacHistoryList.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI

struct MacHistoryList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var clickedGroup: ClickedGroup
    @EnvironmentObject var clickedTask: ClickedTask
    
    @Binding var showInspector: Bool
    @Binding var inspectorView: SelectedInspectorView
    @Binding var navSelection: NavItems?
    
    @AppStorage("limitHistory") private var limitHistory = true
    @AppStorage("historyListLimit") private var historyListLimit = 10
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("totalInclusive") private var totalInclusive = false
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
    
    @State private var showDeleteTaskDialog = false
    @State private var showDeleteTaskGroupDialog = false
    @State private var taskToDelete: FurTask? = nil
    @State private var taskGroupToDelete: FurTaskGroup? = nil
    
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
        .confirmationDialog("Delete task?", isPresented: $showDeleteTaskDialog) {
            Button("Delete", role: .destructive) {
                deleteTask(taskToDelete)
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete all?", isPresented: $showDeleteTaskGroupDialog) {
            Button("Delete", role: .destructive) {
                deleteAllTasks(in: taskGroupToDelete)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all of the tasks in this group.")
        }
        .onAppear {
            inspectorView = .empty
        }
        .onDisappear {
            showInspector = false
            inspectorView = .empty
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
                TaskRow(taskGroup: taskGroup, navSelection: $navSelection)
                    .padding(.bottom, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if taskGroup.tasks.count > 1 {
                            clickedGroup.taskGroup = taskGroup
                            inspectorView = .editTaskGroup
                            showInspector = true
                        } else {
                            clickedTask.task = taskGroup.tasks.first
                            inspectorView = .editTask
                            showInspector = true
                        }
                    }
                    .contextMenu {
                        Button("Repeat") {
                            if !stopWatchHelper.isRunning {
                                var taskTextBuilder = "\(taskGroup.name)"
                                if !taskGroup.project.isEmpty {
                                    taskTextBuilder += " @\(taskGroup.project)"
                                }
                                if !taskGroup.tags.isEmpty {
                                    taskTextBuilder += " \(taskGroup.tags)"
                                }
                                if taskGroup.rate > 0.0 {
                                    taskTextBuilder += " \(chosenCurrency)\(taskGroup.rate)"
                                }

                                TaskTagsInput.shared.text = taskTextBuilder
                                TimerHelper.shared.start()
                                navSelection = .timer
                            }
                        }
                        
                        Button("Edit") {
                            if taskGroup.tasks.count > 1 {
                                clickedGroup.taskGroup = taskGroup
                                inspectorView = .editTaskGroup
                                showInspector = true
                            } else {
                                clickedTask.task = taskGroup.tasks.first
                                inspectorView = .editTask
                                showInspector = true
                            }
                        }
                        
                        Button("Delete") {
                            if taskGroup.tasks.count > 1 {
                                if showDeleteConfirmation {
                                    taskGroupToDelete = taskGroup
                                    showDeleteTaskGroupDialog.toggle()
                                } else {
                                    deleteAllTasks(in: taskGroup)
                                }
                            } else {
                                if showDeleteConfirmation {
                                    taskToDelete = taskGroup.tasks.first
                                    showDeleteTaskDialog.toggle()
                                } else {
                                    deleteTask(taskGroup.tasks.first)
                                }
                            }
                        }
                    }
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
            
            // TODO: Change to firstWhere
            for taskGroup in newGroups {
                if taskGroup.name == task.name,
                   taskGroup.project == task.project,
                   taskGroup.tags == task.tags,
                   taskGroup.rate == task.rate
                {
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
            totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime ?? .now, to: task.stopTime ?? .now).second ?? 0)
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
    
    private func deleteTask(_ task: FurTask?) {
        if let task = task {
            if showInspector, inspectorView == .editTask, clickedTask.task == task {
                showInspector = false
                clickedTask.task = nil
            }
            viewContext.delete(task)
            do {
                taskToDelete = nil
                try viewContext.save()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
    
    private func deleteAllTasks(in taskGroup: FurTaskGroup?) {
        if let taskGroup = taskGroup {
            if let clickedTaskGroup = clickedGroup.taskGroup {
                if showInspector,
                   inspectorView == .editTaskGroup,
                   areTaskGroupsEqual(group1: taskGroup, group2: clickedTaskGroup)
                {
                    showInspector = false
                    clickedGroup.taskGroup = nil
                }
            }
            for task in taskGroup.tasks {
                viewContext.delete(task)
            }
            do {
                taskGroupToDelete = nil
                try viewContext.save()
            } catch {
                print("Error deleting task group: \(error)")
            }
        }
    }
    
    private func areTaskGroupsEqual(group1: FurTaskGroup, group2: FurTaskGroup) -> Bool {
        if group1.date == group2.date,
           group1.name == group2.name,
           group1.tags == group2.tags,
           group1.project == group2.project
        {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    MacHistoryList(showInspector: .constant(false), inspectorView: .constant(SelectedInspectorView.editTask), navSelection: .constant(NavItems.history))
}
