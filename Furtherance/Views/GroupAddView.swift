//
//  GroupAddView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 6/11/23.
//

import SwiftUI

struct GroupAddView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var clickedGroup: ClickedGroup
    @Environment(\.dismiss) var dismiss
    @State var taskName: String
    @State var taskTags: String
    @State var selectedStart: Date
    @State var selectedStop: Date
    @State private var titleField = ""
    @State private var tagsField = ""
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]

    var body: some View {
        VStack(spacing: 10) {
            TextField(taskName, text: $titleField)
                .frame(minWidth: 200)
                .disabled(true)
            TextField(taskTags, text: $tagsField)
                .frame(minWidth: 200)
                .disabled(true)
            DatePicker(
                selection: $selectedStart,
                in: getStartRange(),
                displayedComponents: [.hourAndMinute],
                label: { Text("Start") }
            )
            DatePicker(
                selection: $selectedStop,
                in: getStopRange(),
                displayedComponents: [.hourAndMinute],
                label: { Text("Stop") }
            )
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
                    let task = FurTask(context: viewContext)
                    task.id = UUID()
                    task.name = taskName
                    task.startTime = selectedStart
                    task.stopTime = selectedStop
                    task.tags = taskTags
                    try? viewContext.save()
                    clickedGroup.taskGroup?.add(task: task)
                    clickedGroup.taskGroup?.sortTasks()
                    dismiss()
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

struct GropuAddView_Previews: PreviewProvider {
    static var previews: some View {
        GroupAddView(taskName: "Test", taskTags: "#tags", selectedStart: Date.now, selectedStop: Date.now)
    }
}
