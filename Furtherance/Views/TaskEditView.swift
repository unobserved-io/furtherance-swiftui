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
    @AppStorage("showDeleteConfirmation") private var showDeleteConfirmation = true
    @State private var titleField = ""
    @State private var tagsField = ""
    @State private var showDeleteDialog = false
    @State var selectedStart = Date(timeIntervalSinceReferenceDate: 0)
    @State var selectedStop = Date()
    @State var errorMessage = ""
    
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]
    
    func getStartRange() -> ClosedRange<Date> {
        let min = Date(timeIntervalSinceReferenceDate: 0)
        let max = selectedStop
        return min...max
    }
    
    func getStopRange() -> ClosedRange<Date> {
        let min = selectedStart
        let max = Date.now
        return min...max
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button(action: {
                    if showDeleteConfirmation {
                        showDeleteDialog.toggle()
                    } else {
                        deleteTask()
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .imageScale(.large)
                }
            }
            TextField(clickedTask.task?.name ?? "Unknown", text: Binding(
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
                .frame(height: 50)
            Spacer()
                .frame(height: 15)
            HStack(spacing: 20) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
#if os(iOS)
                    .buttonStyle(.bordered)
#endif
                Button(action: {
                    let newTask: FurTask = clickedTask.task!
                    
                    errorMessage = ""
                    var error = [String]()
                    var updated = false
                    if !titleField.trimmingCharacters(in: .whitespaces).isEmpty, titleField != clickedTask.task!.name {
                        if titleField.contains("#") {
                            error.append("Title cannot contain a '#'. Those are reserved for tags.")
                        } else {
                            newTask.name = titleField
                            updated = true
                        }
                    } // else not changed (don't update)
                    
                    if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, tagsField != clickedTask.task!.tags {
                        if !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                            error.append("Tags must start with a '#'.")
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
                            } catch {
                                print("Error updating task \(error)")
                            }
                        }
                        dismiss()
                    } else {
                        if error.count > 1 {
                            errorMessage = "\(error[0])\n\(error[1])"
                        } else {
                            errorMessage = error[0]
                        }
                    }
                }) {
                    Text("Save")
                }
                .keyboardShortcut(.defaultAction)
#if os(iOS)
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
#endif
            }
        }
        .confirmationDialog("Delete task?", isPresented: $showDeleteDialog) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) {}
        }
        .padding()
        .onAppear {
            selectedStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task?.startTime ?? .now)) ?? clickedTask.task!.startTime!
            selectedStop = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task?.stopTime ?? .now)) ?? clickedTask.task!.stopTime!
            titleField = clickedTask.task?.name ?? ""
            tagsField = clickedTask.task?.tags ?? ""
        }
    }
    
    private func deleteTask() {
        viewContext.delete(clickedTask.task!)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting task \(error)")
        }
        dismiss()
    }
}

struct TaskEditView_Previews: PreviewProvider {
    static var previews: some View {
        TaskEditView()
    }
}
