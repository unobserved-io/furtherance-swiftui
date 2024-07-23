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
    
    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
    
    @State var taskName: String
    @State var taskProject: String
    @State var taskTags: String
    @State var taskRate: Double
    @State var selectedStart: Date
    @State var selectedStop: Date
    
    @State private var titleField = ""
    @State private var projectField = ""
    @State private var tagsField = ""
    @State private var rateField = ""
    
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]

    var body: some View {
        VStack(spacing: 10) {
            TextField(taskName, text: $titleField)
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
                .disabled(true)
            
            TextField(taskProject, text: $projectField)
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
                .disabled(true)
            
            TextField(taskTags, text: $tagsField)
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
                .disabled(true)
            
            HStack{
                Text(chosenCurrency)
                TextField(String(taskRate), text: $rateField)
                Text("/hr")
            }
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
#if os(iOS)
                    .buttonStyle(.bordered)
#endif
                Button(action: {
                    let task = FurTask(context: viewContext)
                    task.id = UUID()
                    task.name = taskName
                    task.startTime = selectedStart
                    task.stopTime = selectedStop
                    task.tags = taskTags
                    task.project = taskProject
                    task.rate = taskRate
                    try? viewContext.save()
                    clickedGroup.taskGroup?.add(task: task)
                    clickedGroup.taskGroup?.sortTasks()
                    dismiss()
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

struct GropuAddView_Previews: PreviewProvider {
    static var previews: some View {
        GroupAddView(taskName: "Test", taskProject: "Project", taskTags: "#tags", taskRate: 50.0, selectedStart: Date.now, selectedStop: Date.now)
    }
}
