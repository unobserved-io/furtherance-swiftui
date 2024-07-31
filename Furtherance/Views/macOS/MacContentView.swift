//
//  MacContentView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 8/3/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct MacContentView: View {
	@Binding var showExportCSV: Bool
	@Binding var showInspector: Bool
	@Binding var inspectorView: SelectedInspectorView

	@Environment(\.managedObjectContext) private var viewContext

	@ObservedObject var storeModel = StoreModel.shared

	@StateObject var clickedGroup = ClickedGroup(taskGroup: nil)
	@StateObject var clickedTask = ClickedTask(task: nil)
	@StateObject var clickedShortcut = ClickedShortcut(shortcut: nil)
	@StateObject var autosave = Autosave()

	@AppStorage("defaultView") private var defaultView: NavItems = .timer

	@State private var navSelection: NavItems? = .timer

	// TODO: Create one observable object for everything here that needs to be changed by multiple views
	var body: some View {
		NavigationSplitView {
			List(NavItems.allCases, id: \.self, selection: $navSelection) { navItem in
				NavigationLink(navItem.rawValue.capitalized, value: navItem)
			}
			.navigationSplitViewColumnWidth(min: 180, ideal: 200)
			Spacer()
			if StopWatchHelper.shared.isRunning && navSelection != .timer {
				TimeDisplayView()
			}
		} detail: {
			if let selectedItem = navSelection {
				switch selectedItem {
				case .shortcuts: ShortcutsView(
						showInspector: $showInspector,
						inspectorView: $inspectorView,
						navSelection: $navSelection
					)
					.environmentObject(clickedShortcut)
				case .timer: TimerView(showExportCSV: $showExportCSV)
				case .history: MacHistoryList(
						showInspector: $showInspector,
						inspectorView: $inspectorView,
						navSelection: $navSelection
					)
					.environmentObject(clickedGroup)
					.environmentObject(clickedTask)
				case .report: ReportView()
				}
			} else {
				TimerView(showExportCSV: $showExportCSV)
			}
		}
		.inspector(isPresented: $showInspector) {
			switch inspectorView {
			case .empty:
				ContentUnavailableView("Nothing selected", systemImage: "cursorarrow.rays")
					.toolbar {
						if showInspector {
							ToolbarItem {
								Spacer()
							}
							ToolbarItem {
								Button {
									showInspector = false
								} label: {
									Image(systemName: "sidebar.trailing")
										.help("Hide inspector")
								}
							}
						}
					}
			case .editTaskGroup:
				GroupView(showInspector: $showInspector)
					.environmentObject(clickedGroup)
			case .editTask:
				TaskEditView(showInspector: $showInspector)
					.environmentObject(clickedTask)
					.padding()
			case .addShortcut:
				AddShortcutView(showInspector: $showInspector)
			case .editShortcut:
				EditShortcutView(showInspector: $showInspector)
					.environmentObject(clickedShortcut)
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
}

#Preview {
	MacContentView(showExportCSV: .constant(false), showInspector: .constant(false), inspectorView: .constant(.empty))
}
