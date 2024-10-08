//
//  TimerView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import CoreData
import SwiftData
import SwiftUI

struct TimerView: View {
	@Binding var showExportCSV: Bool

	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.colorScheme) var colorScheme
	@Environment(PassStatusModel.self) var passStatusModel: PassStatusModel

	@Bindable var navigator = Navigator.shared

	@ObservedObject var storeModel = StoreModel.shared
	@State private var stopWatchHelper = StopWatchHelper.shared
	@StateObject var taskTagsInput = TaskTagsInput.shared

	@AppStorage("pomodoro") private var pomodoro = false
	@AppStorage("launchCount") private var launchCount: Int = 0
	@AppStorage("totalInclusive") private var totalInclusive: Bool = false
	@AppStorage("limitHistory") private var limitHistory: Bool = true
	@AppStorage("historyListLimit") private var historyListLimit: Int = 10
	@AppStorage("showDailySum") private var showDailySum: Bool = true
	@AppStorage("showSeconds") private var showSeconds: Bool = true
	@AppStorage("pomodoroMoreTime") private var pomodoroMoreTime: Int = 5
	@AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime: Int = 5
	@AppStorage("pomodoroBigBreak") private var pomodoroBigBreak: Bool = false
	@AppStorage("pomodoroBigBreakInterval") private var pomodoroBigBreakInterval: Int = 4
	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"

	@AppStorage("ptIsRunning") private var ptIsRunning: Bool = false
	@AppStorage("ptIsIntermission") private var ptIsIntermission: Bool = false
	@AppStorage("ptIsExtended") private var ptIsExtended: Bool = false
	@AppStorage("ptLastIntermissionTime") private var ptIntermissionTime: Int = 5
	@AppStorage("ptStartTime") private var ptStartTime: TimeInterval = Date.now.timeIntervalSinceReferenceDate
	@AppStorage("ptStopTime") private var ptStopTime: TimeInterval = Date.now.timeIntervalSinceReferenceDate
	@AppStorage("ptTaskName") private var ptTaskName: String = ""
	@AppStorage("ptTaskTags") private var ptTaskTags: String = ""
	@AppStorage("ptTaskProject") private var ptTaskProject: String = ""
	@AppStorage("ptNameAndTags") private var ptNameAndTags: String = ""

	// TODO: For the Mac version, remove this and calculate everything using todaysTasks
	@SectionedFetchRequest(
		sectionIdentifier: \.startDateRelative,
		sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
		animation: .default
	)
	var tasksByDay: SectionedFetchResults<String, FurTask>

	@FetchRequest(
		entity: FurTask.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
		predicate: NSPredicate(
			format: "(startTime >= %@) AND (startTime < %@)",
			Calendar.current
				.startOfDay(for: Date.now) as NSDate,
			(Calendar.current
				.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date.now)) ?? Date.now) as NSDate
		),
		animation: .default
	) var todaysTasks: FetchedResults<FurTask>

	@StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
	@StateObject var clickedTask = ClickedTask(task: nil)
	@State private var showTaskEditSheet = false
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

	var body: some View {
		NavigationStack(path: $navigator.path) {
			VStack {
				Spacer()

				TimeDisplayView()

				HStack {
					TaskInputView()
						.onSubmit {
							startStopPress()
						}

					Button {
						if stopWatchHelper.pomodoroOnBreak {
							timerHelper.pomodoroStopAfterBreak()
						} else if TaskTagsInput.shared.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
				.onChange(of: taskTagsInput.debouncedText) { _, newVal in
					if StopWatchHelper.shared.isRunning {
						if newVal != timerHelper.nameAndTags {
							if !newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
							   newVal.trimmingCharacters(in: .whitespaces).first != "#",
							   newVal.trimmingCharacters(in: .whitespaces).first != "@",
							   newVal.trimmingCharacters(in: .whitespaces).first != Character(chosenCurrency),
							   TaskTagsInput.shared.text.filter({ $0 == "@" }).count < 2,
							   TaskTagsInput.shared.text.filter({ $0 == Character(chosenCurrency) }).count < 2
							{
								timerHelper.updateTaskAndTagsIfChanged()
								#if os(iOS)
									timerHelper.updatePersistentTimerTaskName()
								#endif
							}
						}
					}
				}

				if stopWatchHelper.isRunning, !stopWatchHelper.pomodoroOnBreak {
					StartTimeModifierView()
				}

				Spacer()

				#if os(iOS)
					if !tasksByDay.isEmpty {
						List {
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
					}
				#endif
			}
			.overlay(alignment: .topTrailing) {
				if showDailySum {
					HStack {
						Text("Recorded today:")
						todaysTotalTimeDisplay
					}
					.font(.title3)
					.padding(15)
				}
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
							.disabled(tasksByDay.count == 0)
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
			.navigationDestination(for: ViewPath.self) { path in
				if path == .group {
					GroupView()
				} else if path == .reports {
					#if os(macOS)
						ChartsView()
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
				#if os(iOS)
					resumeOngoingTimer()
				#endif
			}
			.onReceive(willBecomeActive) { _ in
				#if os(iOS)
					resumeOngoingTimer()
				#endif
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
			.alert("Improper Task Name", isPresented: $navigator.showTaskBeginsWithHashtagAlert) {
				Button("OK") {}
			} message: {
				Text("A task name must be provided before tags. The first character cannot be a '#'.")
			}
			.alert("Improper Task Name", isPresented: $navigator.showTaskBeginsWithAtSymbolAlert) {
				Button("OK") {}
			} message: {
				Text("A task name must be provided before the project. The first character cannot be a '@'.")
			}
			.alert("Improper Task Name", isPresented: $navigator.showTaskBeginsWithCurrencySymbolAlert) {
				Button("OK") {}
			} message: {
				Text("A task name must be provided before the rate. The first character cannot be a '\(chosenCurrency)'.")
			}
			.alert("Improper Task Name", isPresented: $navigator.showTaskContainsMoreThanOneAtSymbolAlert) {
				Button("OK") {}
			} message: {
				Text("A task cannot contain more than one project (marked by '@').")
			}
			.alert("Improper Task Name", isPresented: $navigator.showTaskContainsMoreThanOneCurrencySymbolAlert) {
				Button("OK") {}
			} message: {
				Text("A task cannot contain more than one rate (marked by '\(chosenCurrency)').")
			}
			.alert("Invalid Rate", isPresented: $navigator.showCurrencyNotValidNumberAlert) {
				Button("OK") {}
			} message: {
				Text("The rate is not a valid number.")
			}
			.alert("Task Name Empty", isPresented: $showingTaskEmptyAlert) {
				Button("OK") {}
			} message: {
				Text("The task name cannot be empty.")
			}
			#if os(macOS)
			// Idle alert
			.alert("You have been idle for \(stopWatchHelper.idleLength)", isPresented: stopWatchHelper.showingIdleAlertBinding) {
				Button("Discard", role: .destructive) {
					timerHelper.stop(at: stopWatchHelper.idleStartTime)
				}
				Button("Continue") {
					stopWatchHelper.resetIdle()
				}
			} message: {
				Text("Would you like to discard that time, or continue the clock?")
			}
			#endif
		}
		.environmentObject(clickedGroup)
		.alert(
			"Time's up!",
			isPresented: stopWatchHelper.showingPomodoroEndedAlertBinding
		) {
			Button {
				stopWatchHelper.pomodoroMoreMinutes()
			} label: {
				Text("^[\(pomodoroMoreTime) More Minute](inflect: true)\(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty ? " (Pro)" : "")")
			}.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
			Button("Stop") {
				timerHelper.stop(at: stopWatchHelper.stopTime)
			}
			Button(pomodoroBigBreak && stopWatchHelper.pomodoroSessions % pomodoroBigBreakInterval == 0 ? "Long Break" : "Break") {
				timerHelper.pomodoroStartIntermission()
			}
			.keyboardShortcut(.defaultAction)
		} message: {
			Text("Are you ready to take a break?")
		}
		.alert(
			"Break's over!",
			isPresented: stopWatchHelper.showingPomodoroIntermissionEndedAlertBinding
		) {
			Button("Stop") {
				timerHelper.pomodoroStopAfterBreak()
			}
			Button("Continue") {
				timerHelper.pomodoroNextWorkSession()
			}
			.keyboardShortcut(.defaultAction)
		} message: {
			Text("Time to get back to work.")
		}
		#if os(macOS)
		.toolbar {
			ToolbarItem {
				Button {
					if let taskToRepeat = tasksByDay.first?.first {
						if !stopWatchHelper.isRunning, taskToRepeat.name != nil {
							var taskTextBuilder = "\(taskToRepeat.name ?? "Unknown")"
							if !(taskToRepeat.project?.isEmpty ?? true) {
								taskTextBuilder += " @\(taskToRepeat.project ?? "")"
							}
							if !(taskToRepeat.tags?.isEmpty ?? true) {
								taskTextBuilder += " \(taskToRepeat.tags ?? "")"
							}
							if taskToRepeat.rate > 0.0 {
								taskTextBuilder += " \(chosenCurrency)\(String(format: "%.2f", taskToRepeat.rate))"
							}

							TaskTagsInput.shared.text = taskTextBuilder
							TimerHelper.shared.start()
						}
					}
				} label: {
					Label("Repeat Last", systemImage: "arrow.counterclockwise")
				}
				.help("Repeat last")
				.disabled(tasksByDay.first?.first == nil || stopWatchHelper.isRunning)
			}
		}
		#endif
	}

	private var todaysTotalTimeDisplay: some View {
		if totalInclusive, stopWatchHelper.isRunning, !stopWatchHelper.pomodoroOnBreak {
			Text(
				timerInterval: (Calendar.current.date(byAdding: .second, value: -getTotalTimeToday(), to: stopWatchHelper.startTime) ?? .now) ... stopWatchHelper.stopTime,
				countsDown: false
			)
		} else {
			Text(formatTimeShort(getTotalTimeToday()))
		}
	}

	private func startStopPress() {
		if stopWatchHelper.isRunning {
			timerHelper.stop(at: Date.now)
		} else {
			timerHelper.start()
		}
	}

	private func sectionHeader(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> some View {
		HStack {
			Text(taskSection.id.localizedCapitalized)
			Spacer()
			if showDailySum {
				if taskSection.id == "today", totalInclusive {
					if stopWatchHelper.isRunning, !stopWatchHelper.pomodoroOnBreak {
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

	private func sortTasks(_ taskSection: SectionedFetchResults<String, FurTask>.Element) -> [FurTaskGroup] {
		var newGroups = [FurTaskGroup]()
		for task in taskSection {
			var foundGroup = false

			for taskGroup in newGroups {
				if taskGroup.name == task.name, taskGroup.tags == task.tags {
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

	#if os(iOS)
		private func showHistoryList(_ section: SectionedFetchResults<String, FurTask>.Section) -> some View {
			Section(header: sectionHeader(section)) {
				ForEach(sortTasks(section)) { taskGroup in
					TaskRow(taskGroup: taskGroup)
						.padding(.bottom, 5)
						.contentShape(Rectangle())
						.onTapGesture {
							if taskGroup.tasks.count > 1 {
								clickedGroup.taskGroup = taskGroup
								navigator.openView(.group)
							} else {
								clickedTask.task = taskGroup.tasks.first
								showTaskEditSheet.toggle()
							}
						}
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
									TaskTagsInput.shared.text = "\(taskGroup.name) \(taskGroup.tags)"
									timerHelper.start()
								}
							}
						}
						.disabled(stopWatchHelper.isRunning)
				}
			}
		}
	#endif

	private func resumeOngoingTimer() {
		/// Continue running timer if it was running when the app was closed and it is less than 48 hours old
		#if os(iOS)
			if !stopWatchHelper.isRunning, ptIsRunning {
				let ptStartDate = Date(timeIntervalSinceReferenceDate: ptStartTime)

				stopWatchHelper.startTime = ptStartDate
				timerHelper.startTime = ptStartDate
				timerHelper.taskName = ptTaskName
				timerHelper.taskTags = ptTaskTags
				timerHelper.taskProject = ptTaskProject
				timerHelper.nameAndTags = ptNameAndTags
				TaskTagsInput.shared.text = ptNameAndTags

				if ptIsIntermission {
					let stopTime = Calendar.current.date(byAdding: .minute, value: ptIntermissionTime, to: ptStartDate) ?? Date.now
					if Date.now < stopTime {
						stopWatchHelper.intermissionTime = ptIntermissionTime
						stopWatchHelper.resumeIntermission()
					} else {
						stopWatchHelper.showPomodoroIntermissionEndedAlert()
					}
				} else if ptIsExtended {
					let ptStopTimeDate = Date(timeIntervalSinceReferenceDate: ptStopTime)
					if Date.now < ptStopTimeDate {
						stopWatchHelper.resumeExtended()
					} else {
						stopWatchHelper.stopTime = ptStopTimeDate
						stopWatchHelper.showPomodoroTimesUpAlert()
					}
				} else {
					stopWatchHelper.resume()
				}
			} else if stopWatchHelper.isRunning, ptIsRunning {
				if pomodoro {
					if ptIsIntermission {
						let ptStartDate = Date(timeIntervalSinceReferenceDate: ptStartTime)
						let stopTime = Calendar.current.date(byAdding: .minute, value: ptIntermissionTime, to: ptStartDate) ?? Date.now
						if Date.now > stopTime {
							stopWatchHelper.showPomodoroIntermissionEndedAlert()
						}
					} else if ptIsExtended {
						stopWatchHelper.resumeExtended()
					} else {
						stopWatchHelper.resume()
					}
				}
			}
		#endif
	}

	private func getTotalTimeToday() -> Int {
		todaysTasks
			.reduce(0) {
				$0 + (
					Calendar.current
						.dateComponents(
							[.second],
							from: $1.startTime ?? .now,
							to: $1.stopTime ?? .now
						).second ?? 0
				)
			}
	}
}

#Preview {
	TimerView(showExportCSV: .constant(false))
}
