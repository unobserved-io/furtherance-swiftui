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
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    @AppStorage("showSeconds") private var showSeconds = true
    @StateObject var clickedTask = ClickedTask(task: nil)
    @State private var clickedID = UUID()
    @State private var showingSheet = false
    @State private var overallEditSheet = false
    @State private var groupAddSheet = false
    @State private var showDeleteDialog = false
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
        GridItem(.flexible(maximum: 50))
    ]

    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    VStack {
                        Text(clickedGroup.taskGroup?.name ?? "Unknown")
                            .font(.system(size: 30, weight: .bold))
                            .padding(.bottom, 3)
                        if (clickedGroup.taskGroup?.tags.isEmpty) ?? true {
                            Text("Add tags...")
                                .font(.system(size: 20))
                                .italic()
                        } else {
                            Text(clickedGroup.taskGroup?.tags ?? "Unknown")
                                .font(.system(size: 20))
                        }
                    }
                    Spacer()
                        .frame(width: 30)
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .bold))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            overallEditSheet.toggle()
                        }
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
                Spacer()
                    .frame(height: 40)
                LazyVGrid(columns: columns, spacing: 20) {
                    Text("Start")
                        .font(.system(size: 15, weight: .bold))
                    Text("Stop")
                        .font(.system(size: 15, weight: .bold))
                    Text("Total")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    ForEach(clickedGroup.taskGroup?.tasks ?? [], id: \.self) { task in
                        Text(showSeconds
                            ? dateFormatterWithSeconds.string(from: task.startTime ?? Date.now)
                            : dateFormatterWithoutSeconds.string(from: task.startTime ?? Date.now)
                        )
                        .font(Font.monospacedDigit(.system(size: 15))())
                        Text(showSeconds
                            ? dateFormatterWithSeconds.string(from: task.stopTime ?? Date.now)
                            : dateFormatterWithoutSeconds.string(from: task.stopTime ?? Date.now)
                        )
                        .font(Font.monospacedDigit(.system(size: 15))())
                        Text(showSeconds
                            ? totalFormatterWithSeconds.string(from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now) ?? "00:00:00"
                            : totalFormatterWithoutSeconds.string(from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now) ?? "00:00:00"
                        )
                        .font(Font.monospacedDigit(.system(size: 15))())
                        .bold()
                        Image(systemName: "pencil")
                            .bold()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                clickedTask.task = task
                                clickedID = clickedTask.task?.id ?? UUID() // TODO: Can this be removed?
                                showingSheet.toggle()
                            }
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    groupAddSheet.toggle()
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    if showDeleteConfirmation {
                        showDeleteDialog.toggle()
                    } else {
                        deleteAllTasksInGroup()
                    }
                }) {
                    Image(systemName: "trash.fill")
                }
            }
        }
        .sheet(isPresented: $showingSheet, onDismiss: refreshGroup) {
            TaskEditView().environmentObject(clickedTask)
        }
        .sheet(isPresented: $overallEditSheet) {
            GroupEditView()
        }
        .sheet(isPresented: $groupAddSheet, onDismiss: refreshGroup) {
            GroupAddView(taskName: clickedGroup.taskGroup?.name ?? "Unknown", taskTags: clickedGroup.taskGroup?.tags ?? "#tags", selectedStart: clickedGroup.taskGroup?.tasks.first?.stopTime ?? Date.now, selectedStop: Calendar.current.date(byAdding: .hour, value: 1, to: clickedGroup.taskGroup?.tasks.first?.stopTime ?? Date.now) ?? Date.now)
                .environmentObject(clickedGroup)
        }
        .confirmationDialog("Delete all?", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                deleteAllTasksInGroup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all of the tasks listed here.")
        }
        .padding()
        .frame(minWidth: 360, idealWidth: 400, idealHeight: 600)
    }

    func refreshGroup() {
        if clickedGroup.taskGroup != nil {
            for task in clickedGroup.taskGroup!.tasks {
                if task.id == nil {
                    let index = clickedGroup.taskGroup!.tasks.firstIndex(of: task)
                    clickedGroup.taskGroup!.tasks.remove(at: index!)
                } else {
                    if task.name != clickedGroup.taskGroup!.name || task.tags != clickedGroup.taskGroup!.tags {
                        let index = clickedGroup.taskGroup!.tasks.firstIndex(of: task)
                        clickedGroup.taskGroup!.tasks.remove(at: index!)
                    }
                }
            }
            if clickedGroup.taskGroup!.tasks.count <= 1 {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func deleteAllTasksInGroup() {
        for task in clickedGroup.taskGroup!.tasks {
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
