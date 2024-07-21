//
//  GroupEditView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import SwiftUI

struct GroupEditView: View {
    @EnvironmentObject var clickedGroup: ClickedGroup
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var titleField = ""
    @State private var projectField = ""
    @State private var tagsField = ""
    @State private var errorMessage = ""
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            TextField(clickedGroup.taskGroup?.name ?? "Unknown", text: Binding(
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
            
            TextField(clickedGroup.taskGroup!.project.isEmpty ? "Project" : clickedGroup.taskGroup!.project, text: $projectField)
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
            
            TextField(clickedGroup.taskGroup!.tags.isEmpty ? "#add #tags" : clickedGroup.taskGroup!.tags, text: $tagsField)
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
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .lineLimit(nil)
                    .fixedSize()
                    .multilineTextAlignment(.leading)
            }
            
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
                    errorMessage = ""
                    var error = [String]()
                    var updateName = false
                    var updateProject = false
                    var updateTags = false
                    var newTags = ""
                    if !titleField.trimmingCharacters(in: .whitespaces).isEmpty, titleField != clickedGroup.taskGroup!.name {
                        if titleField.contains("#") || titleField.contains("@") {
                            error.append("Title cannot contain a '#' or '@'.")
                        } else {
                            updateName = true
                        }
                    } // else not changed (don't update)
                    
                    if projectField != clickedGroup.taskGroup!.project {
                        if projectField.contains("#") || projectField.contains("@") {
                            error.append("Project cannot contain a '#' or '@'.")
                        } else {
                            updateProject = true
                        }
                    } // else not changed (don't update)
                    
                    if tagsField != clickedGroup.taskGroup!.tags {
                        if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                            error.append("Tags must start with a '#'.")
                        } else if tagsField.contains("@") {
                            error.append("Tags cannot contain an '@'.")
                        } else {
                            newTags = separateTags(rawString: tagsField)
                            updateTags = true
                        }
                    } // else not changed (don't update)
                    
                    if error.isEmpty {
                        if updateName || updateProject || updateTags {
                            for task in clickedGroup.taskGroup?.tasks ?? [] {
                                if updateName { task.name = titleField }
                                if updateProject { task.project = projectField }
                                if updateTags { task.tags = newTags }
                            }
                            
                            do {
                                try viewContext.save()
                            } catch {
                                print("Error updating task group \(error)")
                            }
                            if updateName { clickedGroup.taskGroup?.name = titleField }
                            if updateProject { clickedGroup.taskGroup?.project = projectField }
                            if updateTags { clickedGroup.taskGroup?.tags = newTags }
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
            .padding(.top, 15)
        }
        .padding()
        .onAppear {
            if let taskGroup = clickedGroup.taskGroup {
                titleField = taskGroup.name
                projectField = taskGroup.project
                tagsField = taskGroup.tags
            }
        }
    }
}

struct GroupEditView_Previews: PreviewProvider {
    static var previews: some View {
        GroupEditView()
    }
}
