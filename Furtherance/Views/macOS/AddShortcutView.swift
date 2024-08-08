//
//  AddShortcutView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 19.07.2024.
//

import SwiftData
import SwiftUI

struct AddShortcutView: View {
    @Binding var showInspector: Bool
    
    @Environment(\.modelContext) private var modelContext

	@Query var shortcuts: [Shortcut]

    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
    
    @State private var titleField: String = ""
    @State private var projectField: String = ""
    @State private var tagsField: String = ""
    @State private var rateField: String = ""
    @State private var pickedColor: Color = Color.random
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 10) {
            TextField("Task name", text: Binding(
                get: { titleField },
                set: { newValue in
                    titleField = newValue.trimmingCharacters(in: ["#", "@"])
                }
            ))
            
            TextField("Project", text: $projectField)
            
            TextField("#tags", text: $tagsField)
            
            HStack{
                Text(chosenCurrency)
                TextField("0.00", text: $rateField)
                Text("/hr")
            }
            
            ColorPicker("Color", selection: $pickedColor)
            
            errorMessage.isEmpty ? nil : Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    showInspector = false
                    resetChanges()
                }

                .keyboardShortcut(.cancelAction)
                #if os(iOS)
                    .buttonStyle(.bordered)
                #endif
                
                Button("Save") {
                    errorMessage = ""
                    var error: [String] = []
                    var unwrappedRate: Double = 0.0
                    
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
                    
                    if !tagsField.trimmingCharacters(in: .whitespaces).isEmpty, !(tagsField.trimmingCharacters(in: .whitespaces).first == "#") {
                        error.append("Tags must start with a '#'.")
                    } else if tagsField.contains("@") {
                        error.append("Tags cannot contain an '@'.")
                    }
                    
                    if rateField.isEmpty {
                        unwrappedRate = 0.0
                    } else if rateField.contains(chosenCurrency) {
                        error.append("Do not include currency symbol ('\(chosenCurrency)') in rate.")
                    } else {
                        if let rate = Double(rateField.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) {
                            unwrappedRate = rate
                        } else {
                            error.append("Rate is not a valid number.")
                        }
                    }

					if error.isEmpty && shortcuts.contains(where: { $0.name == titleField && $0.project == projectField && $0.tags == tagsField && $0.rate == unwrappedRate }) {
						error.append("Shortcut already exists.")
					}

                    // Save shortcut or show error
                    if error.isEmpty {
                        let newShortcut = Shortcut(name: titleField, tags: tagsField, project: projectField, color: pickedColor.hex ?? "A97BEAFF", rate: unwrappedRate)
                        modelContext.insert(newShortcut)
                        showInspector = false
                        resetChanges()
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
        pickedColor = Color.random
        errorMessage = ""
    }
}

#Preview {
    AddShortcutView(showInspector: .constant(false))
}
