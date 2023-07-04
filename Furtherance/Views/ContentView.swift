//
//  ContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var tasksCount: Int
    @Binding var navPath: [String]
    @Binding var showExportCSV: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) private var requestReview
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("totalInclusive") private var totalInclusive = false
    @AppStorage("limitHistory") private var limitHistory = false
    @AppStorage("historyListLimit") private var historyListLimit = 50
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("showSeconds") private var showSeconds = true
    @SectionedFetchRequest(
        sectionIdentifier: \.startDateRelative,
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        animation: .default
    )
    var tasks: SectionedFetchResults<String, FurTask>
    
    @ObservedObject var stopWatch = StopWatch.sharedInstance
    @StateObject var taskTagsInput = TaskTagsInput.sharedInstance
    @StateObject var autosave = Autosave()
    @StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
    @StateObject var clickedTask = ClickedTask(task: nil)
    @State private var showingSheet = false
    @State private var hashtagAlert = false
    @State private var showingTaskEmptyAlert = false
    let timerHelper = TimerHelper.sharedInstance
    #if os(macOS)
        let willBecomeActive = NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
    #else
        let willBecomeActive = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    #endif
    
    
    init(tasksCount: Binding<Int>, navPath: Binding<[String]>, showExportCSV: Binding<Bool>) {
        self._tasksCount = tasksCount
        self._navPath = navPath
        self._showExportCSV = showExportCSV
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
                    #if os(iOS)
                    .disableAutocorrection(true)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentColor, lineWidth: 3)
                    )
                    #endif
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(stopWatch.isRunning)
                    .onSubmit {
                        startStopPress()
                    }
                    Button {
                        if taskTagsInput.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showingTaskEmptyAlert.toggle()
                        } else {
                            startStopPress()
                        }
                    } label: {
                        Image(systemName: stopWatch.isRunning ? "stop.fill" : "play.fill")
                        #if os(iOS)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .foregroundColor(Color.white)
                        #endif
                    }
                }
                .padding(.horizontal)
                tasks.isEmpty ? nil : showTaskHistoryListBasedOnDevice()
            }
            // Update tasks count every time tasks is changed
            .onChange(of: tasks.count) { _ in
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
            .onAppear {
                tasksCount = tasks.count
                
                // Ask for in-app review
                if launchCount > 0 && launchCount % 10 == 0 {
                    DispatchQueue.main.async {
                        requestReview()
                    }
                }
                checkForAutosave()
            }
            .onReceive(willBecomeActive) { _ in
                if !tasks.isEmpty {
                    if !Calendar.current.isDateInToday(tasks[0][0].stopTime ?? Date.now) {
                        viewContext.refreshAllObjects()
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
                Button("OK") {}
            } message: {
                Text("A task name must be provided before tags. The first character cannot be a '#'.")
            }
            // Empty task name alert
            .alert("Task Name Empty", isPresented: $showingTaskEmptyAlert) {
                Button("OK") {}
            } message: {
                Text("The task name cannot be empty.")
            }
#if os(macOS)
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
#endif
            // CSV Export
            .fileExporter(
                isPresented: $showExportCSV,
                document: CSVFile(initialText: dataAsCSV()),
                contentType: UTType.commaSeparatedText,
                defaultFilename: "Furtherance.csv"
            ) { _ in }
            #if os(macOS)
            .frame(minWidth: 360, idealWidth: 400, minHeight: 170, idealHeight: 600)
            #endif
        }
        .environmentObject(clickedGroup)
    }
        
    private func startStopPress() {
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
        
        // Refresh the viewContext if the timer goes past midnight
        let startDate = Calendar.current.dateComponents([.day], from: timerHelper.startTime)
        let stopDate = Calendar.current.dateComponents([.day], from: Date.now)
        if startDate.day != stopDate.day {
            viewContext.refreshAllObjects()
        }
    }
    
    private func sectionHeader(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> some View {
        return HStack {
            Text(taskSection.id.localizedCapitalized)
            Spacer()
            if showDailySum {
                if taskSection.id == "today", totalInclusive {
                    Text(totalSectionTimeIncludingTimer(taskSection, secsElapsed: stopWatch.secondsElapsedPositive))
                } else {
                    Text(totalSectionTime(taskSection))
                }
            }
        }
        .font(.headline)
        .padding(.top).padding(.bottom)
    }
    
    private func totalSectionTime(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> String {
        var totalTime = 0
        for task in taskSection {
            totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
        if showSeconds {
            return formatTimeShort(totalTime)
        } else {
            return formatTimeLongWithoutSeconds(totalTime)
        }
    }

    private func totalSectionTimeIncludingTimer(_ taskSection: SectionedFetchResults<String, FurTask>.Element, secsElapsed: Int) -> String {
        var totalTime = 0
        for task in taskSection {
            totalTime = totalTime + (Calendar.current.dateComponents([.second], from: task.startTime!, to: task.stopTime!).second ?? 0)
        }
        totalTime += secsElapsed
        if showSeconds {
            return formatTimeShort(totalTime)
        } else {
            return formatTimeLongWithoutSeconds(totalTime)
        }
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
    
    private func dataAsCSV() -> String {
        let allData: [FurTask] = fetchAllData()
        var csvString = "Name,Tags,Start Time,Stop Time,Total Seconds\n"
        
        allData.forEach { task in
            csvString += furTaskToString(task)
        }
        
        return csvString
    }
    
    private func fetchAllData() -> [FurTask] {
        let fetchRequest: NSFetchRequest<FurTask> = FurTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    private func furTaskToString(_ task: FurTask) -> String {
        let totalSeconds = task.stopTime?.timeIntervalSince(task.startTime ?? Date.now)
        let startString = localDateFormatter.string(from: task.startTime ?? Date.now)
        let stopString = localDateFormatter.string(from: task.stopTime ?? Date.now)
        return "\(task.name ?? "Unknown"),\(task.tags ?? ""),\(startString),\(stopString),\(Int(totalSeconds ?? 0))\n"
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
                            navPath.append("group")
                        } else {
                            clickedTask.task = taskGroup.tasks.first!
                            showingSheet.toggle()
                        }
                    }
                //TODO: Too easy to accidentally delete?
//                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                        Button("Delete", role: .destructive) {
//                            taskGroup.tasks.forEach { task in
//                                viewContext.delete(task)
//                            }
//                            try? viewContext.save()
//                        }
//                    }
                    .disabled(stopWatch.isRunning)
            }
        }
    }
    
    private func showTaskHistoryListBasedOnDevice() -> some View {
            #if os(macOS)
            return ScrollView {
                Form {
                    if limitHistory {
                        ForEach(0 ..< historyListLimit, id: \.self) { index in
                            showHistoryList(tasks[index])
                        }
                    } else {
                        ForEach(tasks) { section in
                            showHistoryList(section)
                        }
                    }
                }
                .padding(.horizontal)
            }
            #else
            return List {
                if limitHistory {
                    ForEach(0 ..< historyListLimit, id: \.self) { index in
                        showHistoryList(tasks[index])
                    }
                    .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
                } else {
                    ForEach(tasks) { section in
                        showHistoryList(section)
                    }
                    .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
                }
            }
            .scrollContentBackground(.hidden)
            #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tasksCount: .constant(0), navPath: .constant([""]), showExportCSV: .constant(false)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
