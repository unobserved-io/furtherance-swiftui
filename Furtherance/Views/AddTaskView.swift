//
//  AddTaskView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 6/11/23.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var selectedStart: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date.now) ?? Date.now
    @State private var selectedStop: Date = .now
    @State private var titleField = ""
    @State private var tagsField = ""
    @State private var errorMessage = ""
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]

    var body: some View {
        VStack(spacing: 10) {
            TextField("Task name", text: $titleField)
                .frame(minWidth: 200)
            TextField("#tags", text: $tagsField)
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
            HStack(spacing: 10) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                Button(action: {
                    errorMessage = ""
                    var error = [String]()
                    if titleField.trimmingCharacters(in: .whitespaces).isEmpty {
                        error.append("Title cannot be empty.")
                    } else {
                        if titleField.contains("#") {
                            error.append("Title cannot contain a '#'. Those are reserved for tags.")
                        }
                    }

                    if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty {
                        if !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                            error.append("Tags must start with a '#'.")
                        }
                    }

                    if error.isEmpty {
                        let task = FurTask(context: viewContext)
                        task.id = UUID()
                        task.name = titleField
                        task.startTime = selectedStart
                        task.stopTime = selectedStop
                        task.tags = separateTags(rawString: tagsField)
                        try? viewContext.save()
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
        .padding()
    }

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
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
    }
}
