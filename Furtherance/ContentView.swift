//
//  ContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Binding var tasksCount: Int
    @Binding var navPath: [String]
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("launchCount") private var launchCount = 0
    @SectionedFetchRequest(
        sectionIdentifier: \.startDateRelative,
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        animation: .default
    )
    var tasks: SectionedFetchResults<String, FurTask>
    
    @ObservedObject var stopWatch = StopWatch.sharedInstance
    @ObservedObject var taskTagsInput = TaskTagsInput.sharedInstance
    @ObservedObject var autosave = Autosave()
    @StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
    @StateObject var clickedTask = ClickedTask(task: nil)
    @State private var showingSheet = false
    @State private var hashtagAlert = false
    let timerHelper = TimerHelper.sharedInstance
    
    init(tasksCount: Binding<Int>, navPath: Binding<[String]>) {
        self._tasksCount = tasksCount
        self._navPath = navPath
        checkForAutosave()
    }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack {
                Text(stopWatch.timeElapsedFormatted)
                    .font(Font.monospacedDigit(.system(size: 80.0))())
                    .lineLimit(1)
                    .lineSpacing(0)
                    .allowsTightening(false)
                    .frame(maxHeight: 90)
                    .padding(.horizontal)
                HStack {
                    TextField("Task Name #tag #another tag", text: Binding(
                        get: { taskTagsInput.text },
                        set: { newValue in
                            if taskTagsInput.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                taskTagsInput.text = newValue.trimmingCharacters(in: ["#"])
                            } else {
                                taskTagsInput.text = newValue
                            }
                        }
                    ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(stopWatch.isRunning)
                        .onSubmit {
                            startStopPress()
                        }
                    Button {
                        startStopPress()
                    } label: {
                        Image(systemName: stopWatch.isRunning ? "stop.fill" : "play.fill")
                    }
                    .disabled(taskTagsInput.text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                tasks.isEmpty ? nil : ScrollView {
                    Form {
                        ForEach(tasks) { section in
                            Section(header: sectionHeader(section)) {
                                ForEach(sortTasks(section)) { taskGroup in
                                    TaskRow(taskGroup: taskGroup)
                                        .padding(.bottom, 5)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if taskGroup.tasks.count > 1 {
                                                clickedGroup.taskGroup = taskGroup
                                                navPath.append("group")
                                            } else {
                                                clickedTask.task = taskGroup.tasks.first!
                                                showingSheet.toggle()
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            // Update tasks count every time tasks is changed
            .onChange(of: tasks.count) { newValue in
                tasksCount = tasks.count
            }
            .navigationDestination(for: String.self) { s in
                if s == "group" {
                    GroupView()
                } else if s == "reports" {
                    ReportsView()
                        .navigationTitle("Time Reports")
                }
            }
            // Initial task count update when view is loaded
            .onAppear() {
                tasksCount = tasks.count
                
                // Ask for in-app review
                if launchCount > 0 && launchCount % 10 == 0 {
                    DispatchQueue.main.async {
                        requestReview()
                    }
                }
            }
            // Task edit sheet
            .sheet(isPresented: $showingSheet) {
                TaskEditView().environmentObject(clickedTask)
            }
            // Autosave alert
            .alert("Autosave Restored", isPresented: $autosave.showAlert) {
                Button("OK") { autosave.read(viewContext: viewContext) }
            } message: {
                Text("Furtherance shut down improperly. An autosave was restored.")
            }
            .alert("Improper Task Name", isPresented: $hashtagAlert) {
                Button("OK") { }
            } message: {
                Text("A task name must be provided before tags. The first character cannot be a '#'.")
            }
            // Idle alert
            .alert(isPresented: $stopWatch.showingAlert) {
                Alert(
                    title: Text("You have been idle for \(stopWatch.howLongIdle)"),
                    message: Text("Would you like to discard that time, or continue the clock?"),
                    primaryButton: .default(Text("Discard"), action: {
                        stopTimer(stopTime: stopWatch.idleStartTime)
                    }),
                    secondaryButton: .cancel(Text("Continue"), action: {
                        stopWatch.resetIdle()
                    })
                )
            }
            .frame(minWidth: 360, idealWidth: 400, minHeight: 170, idealHeight: 600)
        }
        .environmentObject(clickedGroup)
    }
        
    func startStopPress() {
        if stopWatch.isRunning {
            stopTimer(stopTime: Date.now)
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        if taskTagsInput.text.trimmingCharacters(in: .whitespaces).first != "#" {
            stopWatch.start()
            timerHelper.onStart(nameAndTags: taskTagsInput.text)
        } else {
            hashtagAlert.toggle()
        }
    }
    
    private func stopTimer(stopTime: Date) {
        stopWatch.stop()
        timerHelper.onStop(context: viewContext, taskStopTime: stopTime)
        
        // Refresh the viewContext if the timer goes past midnight
        // This prevents the task from going under yesterday, while yesterday remains as today
        let startDate = Calendar.current.dateComponents([.year, .month, .day], from: timerHelper.startTime)
        let stopDate = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
        if startDate.day != stopDate.day {
            viewContext.refreshAllObjects()
        }
        
        taskTagsInput.text = ""
    }
    
    private func sectionHeader(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> some View {
        return HStack {
            Text(taskSection.id.capitalized)
            Spacer()
            Text(totalSectionTime(taskSection))
        }
        .font(.headline)
        .padding(.top).padding(.bottom)
    }
    
    private func totalSectionTime(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> String {
        var totalTime = 0
        for task in taskSection {
            totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
        return formatTimeShort(totalTime)
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
    
    private func checkForAutosave() {
        if autosave.exists() {
            autosave.asAlert()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tasksCount: .constant(0), navPath: .constant([""])).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension FurTask {
    /// Return the string representation of the relative date for the supported range (year, month, and day)
    /// The ranges include today, yesterday, the formatted date, and unknown
    @objc
    var startDateRelative: String {
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        if startTime != nil {
            // Order matters here to avoid overlapping
            if Calendar.current.isDateInToday(startTime!) {
                result = "today"
            } else if Calendar.current.isDateInYesterday(startTime!) {
                result = "yesterday"
            } else {
                result = dateFormatter.string(from: startTime!)
            }
        } else {
            result = "unknown"
        }
        return result
    }
}
