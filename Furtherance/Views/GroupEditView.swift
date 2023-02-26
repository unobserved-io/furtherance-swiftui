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
    @State private var tagsField = ""
    @State private var errorMessage = ""
    private let buttonColumns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.fixed(70)),
    ]
    
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
            TextField(clickedGroup.taskGroup?.name ?? "Unknown", text: $titleField)
                .frame(minWidth: 200)
            TextField(clickedGroup.taskGroup!.tags.isEmpty ? "#add #tags" : clickedGroup.taskGroup!.tags, text: $tagsField)
                .frame(minWidth: 200)
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
                    errorMessage = ""
                    var error = [String]()
                    var updateName = false
                    var updateTags = false
                    var newTags = ""
                    if !titleField.trimmingCharacters(in: .whitespaces).isEmpty, titleField != clickedGroup.taskGroup!.name {
                        if titleField.contains("#") {
                            error.append("Title cannot contain a '#'. Those are reserved for tags.")
                        } else {
                            updateName = true
                        }
                    } // else not changed (don't update)
                    
                    if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, tagsField != clickedGroup.taskGroup!.tags {
                        if !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                            error.append("Tags must start with a '#'.")
                        } else {
                            newTags = separateTags(rawString: tagsField)
                            updateTags = true
                        }
                    } // else not changed (don't update)
                    
                    if error.isEmpty {
                        if updateName || updateTags {
                            for task in clickedGroup.taskGroup?.tasks ?? [] {
                                let newTask = task
                                if updateName { newTask.name = titleField }
                                if updateTags { newTask.tags = newTags }
                            }
                            
                            do {
                                try viewContext.save()
                            } catch {
                                print("Error updating task group \(error)")
                            }
                            if updateName { clickedGroup.taskGroup?.name = titleField }
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
            }
        }
        .padding()
        .onAppear {
            titleField = clickedGroup.taskGroup!.name
            tagsField = clickedGroup.taskGroup!.tags
        }
    }
}

struct GroupEditView_Previews: PreviewProvider {
    static var previews: some View {
        GroupEditView()
    }
}
