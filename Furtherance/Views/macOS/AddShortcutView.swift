//
//  AddShortcutView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 19.07.2024.
//

import SwiftUI

struct AddShortcutView: View {
    @Binding var showInspector: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var titleField: String = ""
    @State private var projectField: String = ""
    @State private var tagsField: String = ""
    @State private var colorPicked: String = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 10) {
            TextField("Task name", text: Binding(
                get: { titleField },
                set: { newValue in
                    titleField = newValue.trimmingCharacters(in: ["#", "@"])
                }
            ))
//            .frame(minWidth: 200)
            
            TextField("Project", text: $projectField)
//                .frame(minWidth: 200)
            
            TextField("#tags", text: $tagsField)
//                .frame(minWidth: 200)
            
            HStack(spacing: 20) {
                Button {
                    resetChanges()
                    showInspector = false
                } label: {
                    Text("Cancel")
                }

                .keyboardShortcut(.cancelAction)
                #if os(iOS)
                    .buttonStyle(.bordered)
                #endif
                
                Button("Save") {
                    errorMessage = ""
                    var error: [String] = []
                    if !titleField.trimmingCharacters(in: .whitespaces).isEmpty {
                        if titleField.contains("#") || titleField.contains("@") {
                            error.append("Task name cannot contain a '#' or '@'. Those are reserved for tags and projects.")
                        }
                    } else {
                        error.append("Task name cannot be empty.")
                    }
                    
                    if projectField.contains("#") || projectField.contains("@") {
                        error.append("Project cannot contain '#' or '@'.")
                    }
                    
                    if !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                        error.append("Tags must start with a '#'.")
                    } else if tagsField.contains("@") {
                        error.append("Tags cannot contain an '@'.")
                    }

                    // Save shortcut or show error
                    if error.isEmpty {
                        // TODO: Rate entry
                        let newShortcut = Shortcut(name: titleField, tags: tagsField, project: projectField, rate: 0.0)
                        modelContext.insert(newShortcut)
                        resetChanges()
                        showInspector = false
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
        .toolbar {
            if showInspector {
                Text("New Shortcut")
                    .font(.title)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func resetChanges() {
        titleField = ""
        projectField = ""
        tagsField = ""
        colorPicked = ""
        errorMessage = ""
    }
}

#Preview {
    AddShortcutView(showInspector: .constant(false))
}
