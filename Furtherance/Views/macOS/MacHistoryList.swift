//
//  MacHistoryList.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftData
import SwiftUI

struct MacHistoryList: View {
	@Environment(\.modelContext) private var modelContext
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(InspectorModel.self) var inspectorModel: InspectorModel

	@EnvironmentObject var clickedGroup: ClickedGroup
	@EnvironmentObject var clickedTask: ClickedTask

	@Binding var navSelection: NavItems?

	@SectionedFetchRequest(
		sectionIdentifier: \.startDateRelative,
		sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
		animation: .default
	)
	var tasksByDay: SectionedFetchResults<String, FurTask>
	@Query var shortcuts: [Shortcut]

	@AppStorage("limitHistory") private var limitHistory = true
	@AppStorage("historyListLimit") private var historyListLimit = 10
	@AppStorage("showDailySum") private var showDailySum = true
	@AppStorage("totalInclusive") private var totalInclusive = false
	@AppStorage("showSeconds") private var showSeconds = true
	@AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
	@AppStorage("lastDayOpened") private var lastDayOpened: String = localDateFormatter.string(from: Date.now)

	@State private var showDeleteTaskDialog = false
	@State private var showDeleteTaskGroupDialog = false
	@State private var showShortcutExistsAlert = false
	@State private var taskToDelete: FurTask? = nil
	@State private var taskGroupToDelete: FurTaskGroup? = nil
	@State private var stopWatchHelper = StopWatchHelper.shared
	@State private var addTaskSheet = false

	let willBecomeActive = NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)

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
							ForEach(0 ..< historyListLimit, id: \.self) { index in
								if tasksByDay.indices.contains(index) {
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
		.alert("Shortcut Exists", isPresented: $showShortcutExistsAlert) {
			Button("OK") {}
		} message: {
			Text("A shortcut for that task already exists.")
		}
		.onAppear {
			inspectorModel.view = .empty
			let todaysDate = localDateFormatter.string(from: Date.now)
			if lastDayOpened != todaysDate {
				lastDayOpened = todaysDate
			}
		}
		.onReceive(willBecomeActive) { _ in
			let todaysDate = localDateFormatter.string(from: Date.now)
			if lastDayOpened != todaysDate {
				if !tasksByDay.isEmpty {
					viewContext.refreshAllObjects()
				}
				lastDayOpened = todaysDate
			}
		}
		.onDisappear {
			inspectorModel.show = false
			inspectorModel.view = .empty
		}
		.toolbar {
			ToolbarItem {
				Button { addTaskSheet.toggle() } label: {
					Label("Add Item", systemImage: "plus")
				}
			}

			if !inspectorModel.show {
				ToolbarItem {
					Button {
						inspectorModel.show = true
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
		Section(header: sectionHeader(section)) {
			ForEach(sortTasks(section)) { taskGroup in
				TaskRow(taskGroup: taskGroup, navSelection: $navSelection)
					.padding(.bottom, 5)
					.contentShape(Rectangle())
					.onTapGesture {
						if taskGroup.tasks.count > 1 {
							clickedGroup.taskGroup = taskGroup
							inspectorModel.view = .editTaskGroup
							inspectorModel.show = true
						} else {
							clickedTask.task = taskGroup.tasks.first
							inspectorModel.view = .editTask
							inspectorModel.show = true
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
									taskTextBuilder += " \(chosenCurrency)\(String(format: "%.2f", taskGroup.rate))"
								}

								TaskTagsInput.shared.text = taskTextBuilder
								TimerHelper.shared.start()
								navSelection = .timer
							}
						}

						Button("Edit") {
							if taskGroup.tasks.count > 1 {
								clickedGroup.taskGroup = taskGroup
								inspectorModel.view = .editTaskGroup
								inspectorModel.show = true
							} else {
								clickedTask.task = taskGroup.tasks.first
								inspectorModel.view = .editTask
								inspectorModel.show = true
							}
						}

						Button("Create shortcut") {
							if !shortcuts.contains(where: { $0.name == taskGroup.name && $0.project == taskGroup.project && $0.tags == taskGroup.tags && $0.rate == taskGroup.rate }) {
								let newShortcut = Shortcut(
									name: taskGroup.name,
									tags: taskGroup.tags,
									project: taskGroup.project,
									color: Color.random.hex ?? "A97BEAFF",
									rate: taskGroup.rate
								)
								modelContext.insert(newShortcut)
								navSelection = .shortcuts
							} else {
								showShortcutExistsAlert.toggle()
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
		HStack {
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
			if let taskGroup = newGroups.first(where: { $0.isEqual(to: task) }) {
				taskGroup.add(task: task)
			} else {
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
		if let task {
			if inspectorModel.show, inspectorModel.view == .editTask, clickedTask.task == task {
				inspectorModel.show = false
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
		if let taskGroup {
			if let clickedTaskGroup = clickedGroup.taskGroup {
				if inspectorModel.show,
				   inspectorModel.view == .editTaskGroup,
				   areTaskGroupsEqual(group1: taskGroup, group2: clickedTaskGroup)
				{
					inspectorModel.show = false
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
			true
		} else {
			false
		}
	}
}

#Preview {
	MacHistoryList(navSelection: .constant(NavItems.history))
}
