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
    @State private var titleField = ""
    @State private var tagsField = ""
    @State private var showDialog = false
    @State var selectedStart = Date(timeIntervalSinceReferenceDate: 0)
    @State var selectedStop = Date()
    @State var errorMessage = ""
    
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]
    private let timeColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
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
    
    func separateTags(rawString: String) -> String {
        var splitTags = rawString.trimmingCharacters(in: .whitespaces).split(separator: "#")
        // Trim each element and lowercase them
        for i in splitTags.indices {
            splitTags[i] = .init(splitTags[i].trimmingCharacters(in: .whitespaces).lowercased())
        }
        // Don't allow empty tags
        splitTags.removeAll(where: { $0.isEmpty })
        // Don't allow duplicate tags
        let splitTagsUnique = splitTags.uniqued()
        let splitTagsJoined = splitTagsUnique.joined(separator: " #")
        if !splitTagsJoined.trimmingCharacters(in: .whitespaces).isEmpty {
            return "#\(splitTagsJoined)"
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button(action: {
                    showDialog.toggle()
                }) {
                    Image(systemName: "trash.fill")
                }
            }
            TextField(clickedTask.task?.name ?? "Unknown", text: $titleField)
                .frame(minWidth: 200)
            TextField((clickedTask.task?.tags?.isEmpty) ?? true ? "#tags" : clickedTask.task!.tags!, text: $tagsField)
                .frame(minWidth: 200)
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
            LazyVGrid(columns: buttonColumns, spacing: 10) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
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
            }
        }
        .confirmationDialog("Delete task?", isPresented: $showDialog) {
            Button("Delete", role: .destructive) {
                viewContext.delete(clickedTask.task!)
                do {
                    try viewContext.save()
                } catch {
                    print("Error deleting task \(error)")
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .padding()
        .onAppear {
            selectedStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task!.startTime!)) ?? clickedTask.task!.startTime!
            selectedStop = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: clickedTask.task!.stopTime!)) ?? clickedTask.task!.stopTime!
        }
    }
}

struct TaskEditView_Previews: PreviewProvider {
    static var previews: some View {
        TaskEditView()
    }
}
