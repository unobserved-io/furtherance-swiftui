//
//  MacContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct MacContentView: View {
	@Binding var showExportCSV: Bool

	@Environment(\.managedObjectContext) private var viewContext
	@Environment(PassStatusModel.self) var passStatusModel: PassStatusModel
	@Environment(InspectorModel.self) var inspectorModel: InspectorModel
	@Environment(\.passIDs) private var passIDs

	@ObservedObject var storeModel = StoreModel.shared

	@StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
	@StateObject var clickedTask = ClickedTask(task: nil)
	@StateObject var clickedShortcut = ClickedShortcut(shortcut: nil)
	@StateObject var autosave = Autosave()

	@AppStorage("defaultView") private var defaultView: NavItems = .timer
	@AppStorage("pomodoroMoreTime") private var pomodoroMoreTime = 5
	@AppStorage("pomodoroBigBreak") private var pomodoroBigBreak = false
	@AppStorage("idleDetect") private var idleDetect = false
	@AppStorage("totalInclusive") private var totalInclusive = false
	@AppStorage("limitHistory") private var limitHistory = true
	@AppStorage("historyListLimit") private var historyListLimit = 10
	@AppStorage("showIconBadge") private var showIconBadge = false
	@AppStorage("showDailySum") private var showDailySum = true
	@AppStorage("showTags") private var showTags = true
	@AppStorage("showProject") private var showProject = true
	@AppStorage("showEarnings") private var showEarnings = true
	@AppStorage("showSeconds") private var showSeconds = true

	@State private var navSelection: NavItems? = .timer
	@State private var status: EntitlementTaskState<PassStatus> = .loading

	// TODO: Create one observable object for everything here that needs to be changed by multiple views
	var body: some View {
		@Bindable var inspectorModel = inspectorModel
		NavigationSplitView {
			List(NavItems.allCases, id: \.self, selection: $navSelection) { navItem in
				if navItem != .buyPro {
					NavigationLink(navItem.rawValue.capitalized, value: navItem)
				} else if passStatusModel.passStatus == .notSubscribed, storeModel.purchasedIds.isEmpty {
					NavigationLink("Buy Pro", value: navItem)
				}
			}
			.navigationSplitViewColumnWidth(min: 180, ideal: 200)
			Spacer()
			if StopWatchHelper.shared.isRunning, navSelection != .timer {
				TimeDisplayView()
			}
		} detail: {
			if let selectedItem = navSelection {
				switch selectedItem {
				case .shortcuts: ShortcutsView(
						navSelection: $navSelection
					)
					.environmentObject(clickedShortcut)
				case .timer: TimerView(showExportCSV: $showExportCSV)
				case .history: MacHistoryList(
						navSelection: $navSelection
					)
					.environmentObject(clickedGroup)
					.environmentObject(clickedTask)
				case .report: ReportView()
				case .buyPro: ProSubscribeView(navSelection: $navSelection)
				}
			} else {
				TimerView(showExportCSV: $showExportCSV)
			}
		}
		.inspector(isPresented: $inspectorModel.show) {
			switch inspectorModel.view {
			case .empty:
				ContentUnavailableView("Nothing selected", systemImage: "cursorarrow.rays")
					.toolbar {
						if inspectorModel.show {
							ToolbarItem {
								Spacer()
							}
							ToolbarItem {
								Button {
									inspectorModel.show = false
								} label: {
									Image(systemName: "sidebar.trailing")
										.help("Hide inspector")
								}
							}
						}
					}
			case .editTaskGroup:
				GroupView()
					.environmentObject(clickedGroup)
			case .editTask:
				TaskEditView()
					.environmentObject(clickedTask)
					.padding()
			case .addShortcut:
				AddShortcutView()
			case .editShortcut:
				EditShortcutView()
					.environmentObject(clickedShortcut)
			}
		}
		.subscriptionStatusTask(for: "21523359") { taskStatus in
			status = await taskStatus.map { statuses in
				await ProductSubscription.shared.status(
					for: statuses,
					ids: passIDs
				)
			}
			switch status {
			case let .failure(error):
				passStatusModel.passStatus = .notSubscribed
				print("Failed to check subscription status: \(error)")
			case let .success(status):
				passStatusModel.passStatus = status
				if passStatusModel.passStatus == .notSubscribed, storeModel.purchasedIds.isEmpty {
					Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { _ in
						Task {
							if await storeModel.purchasedIds.isEmpty {
								await resetPaywalledFeatures()
							}
						}
					}
				}
			case .loading: break
			@unknown default: break
			}
		}
		.alert("Autosave Restored", isPresented: $autosave.showAlert) {
			Button("OK") { Task { await autosave.read(viewContext: viewContext) } }
		} message: {
			Text("Furtherance shut down improperly. An autosave was restored.")
		}
		.onAppear {
			navSelection = defaultView

			Task {
				await checkForAutosave()
			}
		}
		// CSV Export
		.fileExporter(
			isPresented: $showExportCSV,
			document: CSVFile(initialText: dataAsCSV()),
			contentType: UTType.commaSeparatedText,
			defaultFilename: "Furtherance.csv"
		) { _ in }
		#if os(macOS)
			.frame(minWidth: 360, idealWidth: 450, minHeight: 170, idealHeight: 700)
		#endif
	}

	private func checkForAutosave() async {
		if await autosave.exists() {
			autosave.asAlert()
		}
	}

	private func dataAsCSV() -> String {
		let allData: [FurTask] = fetchAllData()
		var csvString = "Name,Project,Tags,Rate,Start Time,Stop Time,Total Seconds\n"

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
		return "\(task.name ?? "Unknown"),\(task.project ?? ""),\(task.tags ?? ""),\(task.rate),\(startString),\(stopString),\(Int(totalSeconds ?? 0))\n"
	}

	private func resetPaywalledFeatures() async {
		pomodoroMoreTime = 5
		pomodoroBigBreak = false
		idleDetect = false
		totalInclusive = false
		limitHistory = true
		historyListLimit = 10
		showIconBadge = false
		showDailySum = true
		showTags = true
		showProject = true
		showEarnings = true
		showSeconds = true
	}
}

#Preview {
	MacContentView(showExportCSV: .constant(false))
}
