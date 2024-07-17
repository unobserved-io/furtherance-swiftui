//
//  TaskEditView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var clickedTask: ClickedTask
    @Environment(\.dismiss) var dismiss
    
    @Binding var showInspector: Bool
    
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    
    @State private var titleField = ""
    @State private var projectField = ""
    @State private var tagsField = ""
    @State private var showDeleteDialog = false
    
    @State var selectedStart = Date(timeIntervalSinceReferenceDate: 0)
    @State var selectedStop = Date()
    @State var errorMessage = ""
    
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]
    
    init(showInspector: Binding<Bool> = .constant(false)) {
        _showInspector = showInspector
    }
    
    var body: some View {
        NavigationStack {
            if clickedTask.task == nil {
                ContentUnavailableView(
                    "No Task",
                    systemImage: "cursorarrow.click.badge.clock",
                    description: Text("Select a task to edit it.")
                )
            } else {
                VStack(spacing: 10) {
                    TextField(clickedTask.task?.name ?? "Task", text: Binding(
                        get: { titleField },
                        set: { newValue in
                            titleField = newValue.trimmingCharacters(in: ["#"])
                        }
                    ))
                    #if os(macOS)
                    .frame(minWidth: 200)
                    #else
                    .frame(minHeight: 30)
                    .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    )
                    #endif
                    
                    TextField((clickedTask.task?.project?.isEmpty) ?? true ? "Project" : clickedTask.task!.project!, text: $projectField)
                    #if os(macOS)
                        .frame(minWidth: 200)
                    #else
                        .frame(minHeight: 30)
                        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        )
                    #endif
                    
                    TextField((clickedTask.task?.tags?.isEmpty) ?? true ? "#tags" : clickedTask.task!.tags!, text: $tagsField)
                    #if os(macOS)
                        .frame(minWidth: 200)
                    #else
                        .frame(minHeight: 30)
                        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        )
                    #endif
                    
                    DatePicker(
                        selection: $selectedStart,
                        in: getStartRange(),
                        displayedComponents: [.date, .hourAndMinute],
                        label: { Text("Start") }
                    )
                    DatePicker(
                        selection: $selectedStop,
                        in: getStopRange(),
                        displayedComponents: [.date, .hourAndMinute],
                        label: { Text("Stop") }
                    )
                    errorMessage.isEmpty ? nil : Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 20) {
                        Button {
                            resetChanges()
                        } label: {
                            Text("Undo Changes") // TODO: Maybe this should just say Undo Changes
                        }

                        .keyboardShortcut(.cancelAction)
                        #if os(iOS)
                            .buttonStyle(.bordered)
                        #endif
                        
                        Button("Save") {
                            let newTask: FurTask = clickedTask.task!
                            
                            errorMessage = ""
                            var error = [String]()
                            var updated = false
                            if !titleField.trimmingCharacters(in: .whitespaces).isEmpty, titleField != clickedTask.task!.name {
                                if titleField.contains("#") || titleField.contains("@") {
                                    error.append("Title cannot contain a '#' or '@'. Those are reserved for tags and projects.")
                                } else {
                                    newTask.name = titleField
                                    updated = true
                                }
                            } // else not changed (don't update)
                            
                            if !projectField.trimmingCharacters(in: .whitespaces).isEmpty, projectField != clickedTask.task!.project {
                                if projectField.contains("#") || projectField.contains("@") {
                                    error.append("Project name cannot contain '#' or '@'.")
                                } else {
                                    newTask.project = projectField
                                    updated = true
                                }
                            } // else not changed (don't update)
                            
                            if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, tagsField != clickedTask.task!.tags {
                                if !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                                    error.append("Tags must start with a '#'.")
                                } else if tagsField.contains("@") {
                                    error.append("Tags cannot contain '@'.")
                                } else {
                                    newTask.tags = separateTags(rawString: tagsField)
                                    updated = true
                                }
                            } // else not changed (don't update)
                            
                            if selectedStart != Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newTask.startTime!)) ?? newTask.startTime {
                                newTask.startTime = selectedStart
                                updated = true
                            } // else not changed (don't update)\
                            
                            if selectedStop != Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newTask.stopTime!)) ?? newTask.stopTime {
                                newTask.stopTime = selectedStop
                                updated = true
                            } // else not changed (don't update)
                            
                            // Update DB or show error
                            if error.isEmpty {
                                if updated {
                                    do {
                                        try viewContext.save()
                                        showInspector = false
                                    } catch {
                                        print("Error updating task \(error)")
                                    }
                                }
                            } else {
                                for (index, element) in error.enumerated() {
                                    if index == 0 {
                                        errorMessage = element
                                    } else {
                                        errorMessage += "\n" + element
                                    }
                                    
                                }
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        #if os(iOS)
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        #endif
                    }
                    .padding(.top, 15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding()
        .confirmationDialog("Delete task?", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar {
            if showInspector {
                ToolbarItem {
                    Spacer()
                }
                
                ToolbarItem {
                    Button {
                        if showDeleteConfirmation {
                            showDeleteDialog.toggle()
                        } else {
                            deleteTask()
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem {
                    Button {
                        showInspector = false
                    } label: {
                        Image(systemName: "sidebar.trailing")
                    }
                }
            }
        }
        .onAppear {
            resetChanges()
        }
    }
    
    private func getStartRange() -> ClosedRange<Date> {
        let min = Date(timeIntervalSinceReferenceDate: 0)
        let max = selectedStop
        return min...max
    }
    
    private func getStopRange() -> ClosedRange<Date> {
        let min = selectedStart
        let max = Date.now
        return min...max
    }
    
    private func deleteTask() {
        if clickedTask.task != nil {
            viewContext.delete(clickedTask.task!)
            do {
                try viewContext.save()
                showInspector = false
            } catch {
                print("Error deleting task \(error)")
            }
        }
    }
    
    private func resetChanges() {
        selectedStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task?.startTime ?? .now)) ?? clickedTask.task!.startTime!
        selectedStop = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task?.stopTime ?? .now)) ?? clickedTask.task!.stopTime!
        titleField = clickedTask.task?.name ?? ""
        projectField = clickedTask.task?.project ?? ""
        tagsField = clickedTask.task?.tags ?? ""
    }
}

struct TaskEditView_Previews: PreviewProvider {
    static var previews: some View {
        TaskEditView(showInspector: .constant(false))
    }
}
