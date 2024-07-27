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
    
    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
    
    @State private var hovering: UUID? = nil
    @State private var showDeleteAlert: Bool = false
	@State private var shortcutToDelete: Shortcut? = nil

    @StateObject var taskTagsInput = TaskTagsInput.shared
    
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    private let timerHelper = TimerHelper.shared
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.itemSpacing / 2.0) {
                ForEach(shortcuts) { shortcut in
                    shortcutTile(for: shortcut)
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
		.alert("Delete?", isPresented: $showDeleteAlert) {
			// Cancel is automatically shown when a button is 'destructive' on Mac
			Button("Delete", role: .destructive) {
				if let shortcutToDelete {
					modelContext.delete(shortcutToDelete)
				}
			}
		} message: {
			Text("Are you certain you want to delete this shortcut?")
		}
    }
    
    private func shortcutTile(for shortcut: Shortcut) -> some View {
        let fontColor = calculateFontColor(bgColor: Color(hex: shortcut.colorHex))
        return VStack(alignment: .leading, spacing: 10.0) {
            Text(shortcut.name)
                .foregroundStyle(fontColor)
                .font(.title)
                .bold()
                .lineLimit(2)
                .help(shortcut.name)
            
            if !shortcut.project.isEmpty {
                Text("@\(shortcut.project)")
                    .foregroundStyle(fontColor)
                    .font(.title2)
                    .help(shortcut.project)
            }
            
            if !shortcut.tags.isEmpty {
                Text(shortcut.tags)
                    .foregroundStyle(fontColor)
                    .help(shortcut.tags)
            }
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
            if shortcut.rate > 0 {
                HStack(spacing: 0) {
                    Text(shortcut.rate, format: .currency(code: getCurrencyCode(for: chosenCurrency)))
                    Text(" / hr")
                }
                .foregroundStyle(fontColor)
                .bold()
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
				shortcutToDelete = shortcut
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
            if !StopWatchHelper.shared.isRunning {
                var taskTextBuilder = "\(shortcut.name)"
                if !shortcut.project.isEmpty {
                    taskTextBuilder += " @\(shortcut.project)"
                }
                if !shortcut.tags.isEmpty {
                    taskTextBuilder += " \(shortcut.tags)"
                }
                if shortcut.rate > 0.0 {
                    taskTextBuilder += " \(chosenCurrency)\(String(format: "%.2f", shortcut.rate))"
                }
                
                taskTagsInput.text = taskTextBuilder
                timerHelper.start()
                navSelection = .timer
            }
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
