//
//  GroupView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import SwiftUI

struct GroupView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@EnvironmentObject var clickedGroup: ClickedGroup
	@Environment(\.presentationMode) var presentationMode

	@Binding var showInspector: Bool

	@AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
	@AppStorage("showSeconds") private var showSeconds = true
	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"

	@StateObject var clickedTask = ClickedTask(task: nil)

	@State private var showTaskEditSheet = false
	@State private var overallEditSheet = false
	@State private var groupAddSheet = false
	@State private var showDeleteDialog = false
	@State private var showToolbar = true

	private let totalFormatterWithSeconds: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.zeroFormattingBehavior = .pad
		return formatter
	}()

	private let totalFormatterWithoutSeconds: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute]
		formatter.zeroFormattingBehavior = .pad
		return formatter
	}()

	private let dateFormatterWithSeconds: DateFormatter = {
		let dateformat = DateFormatter()
		dateformat.dateFormat = "HH:mm:ss"
		return dateformat
	}()

	private let dateFormatterWithoutSeconds: DateFormatter = {
		let dateformat = DateFormatter()
		dateformat.dateFormat = "HH:mm"
		return dateformat
	}()

	private let columns: [GridItem] = [
		GridItem(.flexible()),
		GridItem(.flexible()),
		GridItem(.flexible()),
		GridItem(.flexible(maximum: 50)),
	]

	init(showInspector: Binding<Bool> = .constant(false)) {
		_showInspector = showInspector
	}

	var body: some View {
		NavigationStack {
			if clickedGroup.taskGroup == nil {
				ContentUnavailableView(
					"No Task",
					systemImage: "cursorarrow.click.badge.clock",
					description: Text("Select a task to edit it.")
				)
			} else {
				VStack(spacing: 3) {
					Text(clickedGroup.taskGroup?.name ?? "Unknown")
						.font(.title)
						.bold()
						.padding(.bottom, 3)

					if let project = clickedGroup.taskGroup?.project {
						if !project.isEmpty {
							Text(project)
								.font(.title2)
						}
					}

					if let tags = clickedGroup.taskGroup?.tags {
						if !tags.isEmpty {
							Text(tags)
								.font(.title3)
						}
					}

					if let rate = clickedGroup.taskGroup?.rate {
						if rate != 0.0 {
							HStack {
								Text("\(rate.formatted(.currency(code: getCurrencyCode(for: chosenCurrency)))) / hr")
							}
						}
					}
				}

				Form {
					ForEach(clickedGroup.taskGroup?.tasks ?? [], id: \.self) { task in
						let startString = dateFormatterWithoutSeconds.string(from: task.startTime ?? Date.now)
						let stopString = dateFormatterWithoutSeconds.string(from: task.stopTime ?? Date.now)
						let totalString = showSeconds
							? totalFormatterWithSeconds.string(from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now) ?? "00:00:00"
							: totalFormatterWithoutSeconds.string(from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now) ?? "00:00:00"

						// TODO: Make iOS use NavLink?
						#if os(macOS)
							NavigationLink {
								TaskEditView(
									showInspector: $showInspector,
									showGroupToolbar: $showToolbar
								).environmentObject(clickedTask)
							} label: {
								HStack {
									VStack(alignment: .leading) {
										Text("\(startString) to \(stopString)")
											.monospacedDigit()
											.bold()

										Text("Total: \(totalString)")
											.monospacedDigit()
											.font(.caption)
									}
									Spacer()
								}
								.contentShape(Rectangle())
							}
							.simultaneousGesture(TapGesture().onEnded {
								clickedTask.task = task
								showToolbar = false
							})
							.onHover { inside in
								if inside {
									NSCursor.pointingHand.push()
								} else {
									NSCursor.pop()
								}
							}
						#elseif os(iOS)
							HStack {
								VStack(alignment: .leading) {
									Text("\(startString) to \(stopString)")
										.monospacedDigit()
										.bold()

									Text("Total: \(totalString)")
										.monospacedDigit()
										.font(.caption)
								}
								Spacer()
							}
							.contentShape(Rectangle())
							.onTapGesture {
								clickedTask.task = task
								showTaskEditSheet.toggle()
							}
						#endif
					}
				}
				.navigationBarBackButtonHidden()
			}
		}
		.toolbar {
			if showToolbar, showInspector {
				ToolbarItem {
					Button {
						overallEditSheet.toggle()
					} label: {
						Image(systemName: "pencil")
							.help("Edit group")
					}
				}
				ToolbarItem {
					Spacer()
				}
				ToolbarItem {
					Button {
						groupAddSheet.toggle()
					} label: {
						Image(systemName: "plus")
							.help("Add task to group")
					}
				}
				ToolbarItem {
					Button {
						if showDeleteConfirmation {
							showDeleteDialog.toggle()
						} else {
							deleteAllTasksInGroup()
						}
					} label: {
						Image(systemName: "trash.fill")
							.help("Delete group")
					}
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
		#if os(iOS)
		.sheet(isPresented: $showTaskEditSheet, onDismiss: refreshGroup) {
			TaskEditView().environmentObject(clickedTask)
				.presentationDetents([.taskBar])
		}
		#endif
		.sheet(isPresented: $overallEditSheet, onDismiss: refreshGroup) {
			GroupEditView()
			#if os(iOS)
				.presentationDetents([.groupNameBar])
			#endif
		}
		.sheet(isPresented: $groupAddSheet, onDismiss: refreshGroup) {
			GroupAddView(
				taskName: clickedGroup.taskGroup?.name ?? "Unknown",
				taskProject: clickedGroup.taskGroup?.project ?? "",
				taskTags: clickedGroup.taskGroup?.tags ?? "",
				taskRate: clickedGroup.taskGroup?.rate ?? 0.0,
				selectedStart: Calendar.current.date(byAdding: .hour, value: -1, to: Date.now) ?? Date.now,
				selectedStop: Date.now
			)
			.environmentObject(clickedGroup)
			#if os(iOS)
				.presentationDetents([.taskBar])
			#endif
		}
		.confirmationDialog("Delete all?", isPresented: $showDeleteDialog) {
			Button("Delete", role: .destructive) {
				deleteAllTasksInGroup()
				showInspector = false
				clickedGroup.taskGroup = nil
				clickedTask.task = nil
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("This will delete all of the tasks in this group.")
		}
	}

	func refreshGroup() {
		clickedGroup.taskGroup = clickedGroup.taskGroup
		if clickedGroup.taskGroup != nil {
			for task in clickedGroup.taskGroup?.tasks ?? [] {
				let taskDate = localDateFormatter.string(from: task.startTime ?? Date.now)
				if task.id == nil {
					if let index = clickedGroup.taskGroup?.tasks.firstIndex(of: task) {
						clickedGroup.taskGroup?.tasks.remove(at: index)
					}
				} else {
					if task.name != clickedGroup.taskGroup?.name
						|| task.tags != clickedGroup.taskGroup?.tags
						|| taskDate != clickedGroup.taskGroup?.date
					{
						if let index = clickedGroup.taskGroup?.tasks.firstIndex(of: task) {
							clickedGroup.taskGroup?.tasks.remove(at: index)
						}
					}
				}
			}
			if clickedGroup.taskGroup?.tasks.count ?? 0 <= 1 {
				presentationMode.wrappedValue.dismiss()
			}
		}
	}

	private func deleteAllTasksInGroup() {
		for task in clickedGroup.taskGroup?.tasks ?? [] {
			viewContext.delete(task)
		}
		do {
			try viewContext.save()
		} catch {
			print("Error deleting task \(error)")
		}
		presentationMode.wrappedValue.dismiss()
	}
}

struct GroupView_Previews: PreviewProvider {
	static var previews: some View {
		GroupView()
	}
}
