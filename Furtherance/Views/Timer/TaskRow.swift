//
//  TaskRow.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import SwiftUI

struct TaskRow: View {
    var taskGroup: FurTaskGroup
    @Binding var navSelection: NavItems?
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("showTags") private var showTags = true
    @AppStorage("showSeconds") private var showSeconds = true
    
    @State var stopWatchHelper = StopWatchHelper.shared

    var body: some View {
        HStack(alignment: .center) {
            taskGroup.tasks.count == 1 ? nil : Image(systemName: taskGroup.tasks.count <= 50 ? "\(taskGroup.tasks.count).circle.fill" : "ellipsis.circle.fill").foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(taskGroup.name)
                    .fontWeight(.bold)
                    .truncationMode(.tail)
                    .frame(minWidth: 20)
                    .help(taskGroup.name)

                if !taskGroup.tags.isEmpty && showTags {
                    Text(taskGroup.tags)
                        .lineLimit(1)
                        .opacity(0.626)
                        .frame(minWidth: 20)
                        .truncationMode(.middle)
                        .help(taskGroup.tags)
                }
            }

            Spacer()

            Text(showSeconds ? formatTimeShort(taskGroup.totalTime) : formatTimeLongWithoutSeconds(taskGroup.totalTime))
                .font(.system(.body).monospacedDigit())
            #if os(macOS)
            Button {
                if !stopWatchHelper.isRunning {
                    if taskGroup.project.isEmpty {
                        TaskTagsInput.shared.text = "\(taskGroup.name) \(taskGroup.tags)"
                    } else {
                        TaskTagsInput.shared.text = "\(taskGroup.name) @\(taskGroup.project) \(taskGroup.tags)"
                    }
                    TimerHelper.shared.start()
                    navSelection = .timer
                }
            } label: {
                Image(systemName: "arrow.counterclockwise.circle")
            }
            .buttonStyle(.borderless)
            .disabled(stopWatchHelper.isRunning)
            #endif
        }
        #if os(macOS)
        .frame(height: 25)
        .padding()
        .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
        .cornerRadius(20)
        #else
        .frame(height: 35)
        #endif
    }
}

struct TaskRow_Previews: PreviewProvider {
    static var previews: some View {
        TaskRow(taskGroup: FurTaskGroup(task: FurTask()), navSelection: .constant(NavItems.history))
    }
}
