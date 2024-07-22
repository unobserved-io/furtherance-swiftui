//
//  ShortcutsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 18.07.2024.
//

import SwiftData
import SwiftUI

struct ShortcutsView: View {
    private static let itemSpacing = 60.0
    private static let itemSize = CGSize(width: 200, height: 170)
    
    @Binding var showInspector: Bool
    @Binding var inspectorView: SelectedInspectorView
    @Binding var navSelection: NavItems?
    
    @Environment(\.self) var environment
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var clickedShortcut: ClickedShortcut
    
    @Query var shortcuts: [Shortcut]
    
    @State private var hovering: UUID? = nil
    @State private var showDeleteAlert: Bool = false
    
    @StateObject var taskTagsInput = TaskTagsInput.shared
    
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    private let timerHelper = TimerHelper.shared
    
    var body: some View {
        // TODO: Make vertical spacing in VGrid equivalent to horizontal spacing (dynamic)
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.itemSpacing / 2.0) {
                ForEach(shortcuts) { shortcut in
                    shortcutTile(for: shortcut)
                        .alert("Delete?", isPresented: $showDeleteAlert) {
                            // Cancel is automatically shown when a button is 'destructive' on Mac
                            Button("Delete", role: .destructive) { modelContext.delete(shortcut) }
                        } message: {
                            Text("Are you certain you want to delete this shortcut?")
                        }
                }
            }
            .padding(.vertical, Self.itemSpacing / 2.0)
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
                inspectorView = .empty
            }
            Spacer()
        }
    }
    
    private func shortcutTile(for shortcut: Shortcut) -> some View {
        // TODO: Full task name on hover if it is cut off
        VStack(alignment: .leading, spacing: 10.0) {
            let fontColor = calculateFontColor(bgColor: Color(hex: shortcut.colorHex))
            Text(shortcut.name)
                .foregroundStyle(fontColor)
                .font(.title)
                .bold()
                .lineLimit(2)
            Text("@\(shortcut.project)")
                .foregroundStyle(fontColor)
                .font(.title2)
            Text(shortcut.tags) // TODO: Print all with '#'
                .foregroundStyle(fontColor)
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
        .contextMenu {
            Button("Edit") {
                clickedShortcut.shortcut = shortcut
                inspectorView = .editShortcut
                showInspector = true
            }
            
            Button("Delete") {
                showDeleteAlert.toggle()
            }
        }
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            if shortcut.project.isEmpty {
                taskTagsInput.text = shortcut.name + " " + shortcut.tags
            } else {
                taskTagsInput.text = shortcut.name + " @" + shortcut.project + " " + shortcut.tags
            }
            timerHelper.start()
            navSelection = .timer
        }
    }
    
    private func calculateFontColor(bgColor: Color?) -> Color {
        if let bg = bgColor {
            let components = bg.resolve(in: environment)
            
            return isLightColor(
                red: components.red,
                green: components.green,
                blue: components.blue
            )
                ? .black : .white
        } else {
            return .primary
        }
    }
    
    private func isLightColor(red: Float, green: Float, blue: Float) -> Bool {
        let lightRed = red > 0.65
        let lightGreen = green > 0.65
        let lightBlue = blue > 0.65
        
        let lightness = [lightRed, lightGreen, lightBlue].reduce(0) { $1 ? $0 + 1 : $0 }
        return lightness >= 2
    }
}

// #Preview {
//    ShortcutsView()
// }
