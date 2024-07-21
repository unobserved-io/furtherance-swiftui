//
//  EditShortcutView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 20.07.2024.
//

import SwiftUI

struct EditShortcutView: View {
    private static let defaultColor: String = Color.accentColor.hex ?? "A97BEAFF"
    
    @Binding var showInspector: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var clickedShortcut: ClickedShortcut
    
    @State private var titleField: String = ""
    @State private var projectField: String = ""
    @State private var tagsField: String = ""
    @State private var rateField: Double = 0.0
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
                    if let shortcut = clickedShortcut.shortcut {
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
                            if titleField != shortcut.name {
                                shortcut.name = titleField.trimmingCharacters(in: .whitespaces)
                            }
                            if projectField != shortcut.project {
                                shortcut.project = projectField.trimmingCharacters(in: .whitespaces)
                            }
                            if tagsField != shortcut.tags {
                                shortcut.tags = tagsField.trimmingCharacters(in: .whitespaces)
                            }
                            if pickedColor != shortcut.colorHex {
                                shortcut.colorHex = pickedColor
                            }
                            
                            showInspector = false
                        } else {
                            // TODO: Rate entry
                            for (index, element) in error.enumerated() {
                                if index == 0 {
                                    errorMessage = element
                                } else {
                                    errorMessage += "\n" + element
                                }
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
        .onAppear {
            resetChanges()
        }
        .toolbar {
            if showInspector {
                Text("Edit Shortcut")
                    .font(.title)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func resetChanges() {
        titleField = clickedShortcut.shortcut?.name ?? ""
        projectField = clickedShortcut.shortcut?.project ?? ""
        tagsField = clickedShortcut.shortcut?.tags ?? ""
        rateField = clickedShortcut.shortcut?.rate ?? 0.0
        pickedColor = clickedShortcut.shortcut?.colorHex ?? ""
        errorMessage = ""
    }
}

#Preview {
    EditShortcutView(showInspector: .constant(false))
}
