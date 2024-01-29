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
                    
                    if tagsField != clickedGroup.taskGroup!.tags {
                        if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
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
#if os(iOS)
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
#endif
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
