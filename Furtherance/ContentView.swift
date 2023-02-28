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
    
    @Environment(\.managedObjectContext) private var viewContext
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
    @State private var navPath = [String]()
    @State var sortedTasks = [String: [FurTaskGroup]]()
    @State private var hashtagAlert = false
    let timerHelper = TimerHelper.sharedInstance
    
    init(tasksCount: Binding<Int>) {
        self._tasksCount = tasksCount
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
                HStack {
                    TextField("Task Name #tag #another tag", text: $taskTagsInput.text)
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
                tasks.isEmpty ? nil : ScrollView {
                    Form {
                        ForEach(tasks) { section in
                            Section(header: Text(section.id.capitalized).font(.headline).padding(.top).padding(.bottom)) {
                                ForEach(sortTasks(taskSection: section)) { taskGroup in
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
                }
            }
            // Update tasks count every time tasks is changed
            .onChange(of: tasks.count) { newValue in
                tasksCount = tasks.count
            }
            .navigationDestination(for: String.self) { s in
                if s == "group" {
                    GroupView()
                }
            }
            // Initial task count update when view is loaded
            .onAppear() {
                tasksCount = tasks.count
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
            .padding()
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
        taskTagsInput.text = ""
    }
    
    private func sortTasks(taskSection: SectionedFetchResults<String, FurTask>.Element) -> [FurTaskGroup] {
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
        ContentView(tasksCount: .constant(0)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
