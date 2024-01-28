//
//  ContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var tasksCount: Int
    @Binding var showExportCSV: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var navigator = Navigator.shared
    
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @State private var stopWatchHelper = StopWatchHelper.shared
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("totalInclusive") private var totalInclusive = false
    @AppStorage("limitHistory") private var limitHistory = true
    @AppStorage("historyListLimit") private var historyListLimit = 10
    @AppStorage("showDailySum") private var showDailySum = true
    @AppStorage("showSeconds") private var showSeconds = true

    @SectionedFetchRequest(
        sectionIdentifier: \.startDateRelative,
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        animation: .default
    )
    var tasksByDay: SectionedFetchResults<String, FurTask>
    @Query private var persistentTimer: [PersistentTimer]
    
    @StateObject var taskTagsInput = TaskTagsInput.sharedInstance
    @StateObject var autosave = Autosave()
    @StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
    @StateObject var clickedTask = ClickedTask(task: nil)
    @State private var showTaskEditSheet = false
    @State private var hashtagAlert = false
    @State private var showingTaskEmptyAlert = false
    
    let timerHelper = TimerHelper.shared

    #if os(macOS)
        let willBecomeActive = NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
    #elseif os(iOS)
        let willBecomeActive = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        @State private var showAddTaskSheet = false
        @State private var showProAlert = false
        @State private var showImportCSV = false
        @State private var showInvalidCSVAlert = false
    #endif
    
    init(tasksCount: Binding<Int>, showExportCSV: Binding<Bool>) {
        self._tasksCount = tasksCount
        self._showExportCSV = showExportCSV
    }
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            VStack {
                // This is in its own view for performance
                // Updating the Pomodoro time is far faster this way
                TimeDisplayView()
                    
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
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 3)
                    )
                    #else
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    #endif
                    // TODO: User should be able to change task before it's done
                    .disabled(stopWatchHelper.isRunning)
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
                        Image(systemName: stopWatchHelper.isRunning ? "stop.fill" : "play.fill")
                        #if os(iOS)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .foregroundColor(Color.white)
                        #endif
                    }
                }
                .padding(.horizontal)
                
                tasksByDay.isEmpty ? nil : showTaskHistoryListBasedOnDevice()
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section {
                            Button {
                                navigator.openView(.settings)
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            
                            Button {
                                if storeModel.purchasedIds.isEmpty {
                                    showProAlert.toggle()
                                } else {
                                    navigator.openView(.reports)
                                }
                            } label: {
                                Label("Reports", systemImage: "list.bullet.clipboard")
                            }
                            
                            Button {
                                showAddTaskSheet.toggle()
                            } label: {
                                Label("Add Task", systemImage: "plus")
                            }
                        }
                        
                        Section {
                            Button {
                                if storeModel.purchasedIds.isEmpty {
                                    showProAlert.toggle()
                                } else {
                                    showExportCSV.toggle()
                                }
                            } label: {
                                Label("Export as CSV", systemImage: "square.and.arrow.up")
                            }
                            .disabled(tasksCount == 0)
                            Button {
                                if storeModel.purchasedIds.isEmpty {
                                    showProAlert.toggle()
                                } else {
                                    showImportCSV.toggle()
                                }
                            } label: {
                                Label("Import CSV", systemImage: "square.and.arrow.down")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color.primary)
                    }
                }
            }
            .fileImporter(isPresented: $showImportCSV, allowedContentTypes: [UTType.commaSeparatedText]) { result in
                do {
                    let fileURL = try result.get()
                    if fileURL.startAccessingSecurityScopedResource() {
                        let data = try String(contentsOf: fileURL)
                        // Split string into rows
                        var rows = data.components(separatedBy: "\n")
                        // Remove headers
                        if rows[0] == "Name,Tags,Start Time,Stop Time,Total Seconds" {
                            rows.removeFirst()

                            // Split rows into columns
                            var furTasks = [FurTask]()
                            for row in rows {
                                let columns = row.components(separatedBy: ",")
                                
                                if columns.count == 5 {
                                    let task = FurTask(context: viewContext)
                                    task.id = UUID()
                                    task.name = columns[0]
                                    task.tags = columns[1]
                                    task.startTime = localDateTimeFormatter.date(from: columns[2])
                                    task.stopTime = localDateTimeFormatter.date(from: columns[3])
                                    furTasks.append(task)
                                }
                            }
                            try? viewContext.save()
                        } else {
                            showInvalidCSVAlert.toggle()
                        }
                    }
                    fileURL.stopAccessingSecurityScopedResource()
                } catch {
                    print("Failed to import data: \(error.localizedDescription)")
                }
            }
            .alert("Invalid CSV", isPresented: $showInvalidCSVAlert) {
                Button("OK") {}
            } message: {
                Text("The CSV you chose is not a valid Furtherance CSV.")
            }
            .alert("Upgrade to Pro", isPresented: $showProAlert) {
                Button("Cancel") {}
                if let product = storeModel.products.first {
                    Button(action: {
                        Task {
                            if storeModel.purchasedIds.isEmpty {
                                try await storeModel.purchase()
                            }
                        }
                    }) {
                        Text("Buy Pro \(product.displayPrice)")
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } message: {
                Text("That feature is only available in Furtherance Pro.")
            }
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // Update tasks count every time tasks is changed
            .onChange(of: tasksByDay.count) {
                tasksCount = tasksByDay.count
            }
            .navigationDestination(for: ViewPath.self) { path in
                if path == .group {
                    GroupView()
                } else if path == .reports {
                    #if os(macOS)
                        ReportsView()
                            .navigationTitle("Time Reports")
                    #else
                        IOSReportsView()
                            .navigationTitle("Time Reports")
                            .navigationBarTitleDisplayMode(.inline)
                    #endif
                } else if path == .settings {
                    SettingsView()
                        .navigationTitle("Settings")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                }
            }
            // Initial task count update when view is loaded
            .onAppear {
                tasksCount = tasksByDay.count
                
                #if os(iOS)
                    deleteExtraPersistentTimers()
                    resumeOngoingTimer()
                #endif
                
                #if os(macOS)
                    checkForAutosave()
                #endif
            }
            .onReceive(willBecomeActive) { _ in
                if !tasksByDay.isEmpty {
                    if !Calendar.current.isDateInToday(tasksByDay[0][0].stopTime ?? Date.now) {
                        viewContext.refreshAllObjects()
                    }
                }
            }
            .sheet(isPresented: $showTaskEditSheet) {
                TaskEditView()
                    .environmentObject(clickedTask)
                #if os(iOS)
                    .presentationDetents([.taskBar])
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskView()
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.taskBar])
            }
            #endif
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
            .alert(isPresented: stopWatchHelper.showingIdleAlertBinding) {
                Alert(
                    title: Text("You have been idle for \(stopWatchHelper.idleLength)"),
                    message: Text("Would you like to discard that time, or continue the clock?"),
                    primaryButton: .default(Text("Discard"), action: {
                        timerHelper.stop(stopTime: stopWatchHelper.idleStartTime)
                    }),
                    secondaryButton: .cancel(Text("Continue"), action: {
                        stopWatchHelper.resetIdle()
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
        if stopWatchHelper.isRunning {
            timerHelper.stop(stopTime: Date.now)
        } else {
            timerHelper.start()
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
        
        for task in allData {
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
        let startString = localDateTimeFormatter.string(from: task.startTime ?? Date.now)
        let stopString = localDateTimeFormatter.string(from: task.stopTime ?? Date.now)
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
                            navigator.openView(.group)
                        } else {
                            clickedTask.task = taskGroup.tasks.first!
                            showTaskEditSheet.toggle()
                        }
                    }
                #if os(iOS)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            for task in taskGroup.tasks {
                                viewContext.delete(task)
                            }
                            try? viewContext.save()
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button("Repeat") {
                            if !stopWatchHelper.isRunning {
                                taskTagsInput.text = "\(taskGroup.name) \(taskGroup.tags)"
                                timerHelper.start()
                            }
                        }
                    }
                #endif
                    .disabled(stopWatchHelper.isRunning)
            }
        }
    }
    
    private func showTaskHistoryListBasedOnDevice() -> some View {
        #if os(macOS)
            return ScrollView {
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
                .padding(.horizontal)
            }
        #else
            return List {
                if limitHistory {
                    if tasksByDay.count > historyListLimit {
                        ForEach(0 ..< historyListLimit, id: \.self) { index in
                            showHistoryList(tasksByDay[index])
                        }
                        .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : nil)
                    } else {
                        ForEach(0 ..< tasksByDay.count, id: \.self) { index in
                            showHistoryList(tasksByDay[index])
                        }
                        .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : nil)
                    }
                } else {
                    ForEach(tasksByDay) { section in
                        showHistoryList(section)
                    }
                    .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : nil)
                }
            }
            .scrollContentBackground(.hidden)
        #endif
    }
    
    private func resumeOngoingTimer() {
        /// Continue running timer if it was running when the app was closed and it is less than 48 hours old
        if persistentTimer.first != nil {
            if persistentTimer.first?.isRunning ?? false {
                stopWatchHelper.startTime = persistentTimer.first?.startTime ?? .now
                timerHelper.startTime = persistentTimer.first?.startTime ?? .now
                timerHelper.taskName = persistentTimer.first?.taskName ?? ""
                timerHelper.taskTags = persistentTimer.first?.taskTags ?? ""
                timerHelper.nameAndTags = persistentTimer.first?.nameAndTags ?? ""
                taskTagsInput.text = timerHelper.nameAndTags
                stopWatchHelper.resume()
            }
        }
    }
    
    private func deleteExtraPersistentTimers() {
        /// Make sure there is no more than 1 PersistentTimer, otherwise delete the extras
        /// This is just a fail-safe and should never run
        while persistentTimer.count > 1 {
            modelContext.delete(persistentTimer.last!)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tasksCount: .constant(0), showExportCSV: .constant(false)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
