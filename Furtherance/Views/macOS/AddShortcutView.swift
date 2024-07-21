//
//  AddShortcutView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 19.07.2024.
//

import SwiftUI

struct AddShortcutView: View {
    private static let defaultColor: String = Color.accentColor.hex ?? "A97BEAFF"
    
    @Binding var showInspector: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var titleField: String = ""
    @State private var projectField: String = ""
    @State private var tagsField: String = ""
    // TODO: Change to a random color each time
    @State private var pickedColor: String = Self.defaultColor
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
            
            ColorPicker("Color", selection: Binding(
                get: {
                    Color(hex: pickedColor) ?? .accent
                },
                set: { newValue in
                    pickedColor = newValue.hex ?? Self.defaultColor
                }))
            
            errorMessage.isEmpty ? nil : Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    resetChanges()
                    showInspector = false
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
                        let newShortcut = Shortcut(name: titleField, tags: tagsField, project: projectField, color: pickedColor, rate: 0.0)
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
        pickedColor = Self.defaultColor
        errorMessage = ""
    }
}

#Preview {
    AddShortcutView(showInspector: .constant(false))
}
