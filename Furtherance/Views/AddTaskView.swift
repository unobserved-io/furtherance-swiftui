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
            TextField("#tags", text: $tagsField)
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
            HStack(spacing: 10) {
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
#if os(iOS)
.buttonStyle(.borderedProminent)
.tint(.accentColor)
#endif
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
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
    }
}
