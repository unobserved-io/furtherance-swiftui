//
//  ShortcutsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 18.07.2024.
//

import SwiftData
import SwiftUI

struct ShortcutsView: View {
    private static let itemSpacing = 12.0
    private static let itemSize = CGSize(width: 180, height: 210)
    
    @Binding var showInspector: Bool
    @Binding var inspectorView: SelectedInspectorView
    
    @EnvironmentObject var clickedShortcut: ClickedShortcut
    
    @Query var shortcuts: [Shortcut]
    
    @State private var hovering: UUID? = nil
    
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    
    var body: some View {
        // TODO: Make vertical spacing in VGrid equivalent to horizontal spacing (dynamic)
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                ForEach(shortcuts) { shortcut in
                    shortcutTile(for: shortcut)
                        .contextMenu {
                            Button{
                                clickedShortcut.shortcut = shortcut
                                inspectorView = .editShortcut
                                showInspector = true
                            } label: { Text("Edit") }
                            Button{} label: { Text("Delete") }
                        }
                }
            }
            .padding(.vertical, Self.itemSpacing)
            .toolbar {
                if !showInspector {
                    ToolbarItem {
                        Button {
                            inspectorView = .addShortcut
                            showInspector = true
                        } label: {
                            Label("Add shortcut", systemImage: "plus")
                        }
                    }
                }
            }
            .onDisappear {
                showInspector = false
            }
            Spacer()
        }
    }
    
    private func shortcutTile(for shortcut: Shortcut) -> some View {
        // TODO: Full task name on hover if it is cut off
        VStack(alignment: .leading, spacing: 10.0) {
            Text(shortcut.name)
                .font(.title)
                .bold()
                .lineLimit(2)
            Text("@\(shortcut.project)")
                .font(.title2)
            Text(shortcut.tags) // TODO: Print all with '#'
        }
        .padding(.top, 15)
        .padding(.horizontal, 8)
        .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .topLeading)
        .multilineTextAlignment(.leading)
        .background(
            Color(hex: shortcut.colorHex)?.gradient ?? Color.accentColor.gradient,
            in: RoundedRectangle(cornerRadius: 15)
        )
        .overlay(alignment: .bottomTrailing) {
            if shortcut.rate != 0 {
                // TODO: Change currency based on user
                Text(shortcut.rate, format: .currency(code: "USD"))
                    .bold()
                    .monospacedDigit()
                    .padding(8)
            }
        }
    }
}

// #Preview {
//    ShortcutsView()
// }
