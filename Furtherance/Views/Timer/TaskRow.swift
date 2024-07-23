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

    @AppStorage("showProject") private var showProject = true
    @AppStorage("showTags") private var showTags = true
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("chosenCurrency") private var chosenCurrency: String = "$"

    @State var stopWatchHelper = StopWatchHelper.shared

    var body: some View {
        HStack(alignment: .center) {
            if taskGroup.tasks.count == 1 {
                Spacer().frame(width: 22)
            } else {
                Image(systemName: taskGroup.tasks.count <= 50 ? "\(taskGroup.tasks.count).circle.fill" : "ellipsis.circle.fill")
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(taskGroup.name)
                    .bold()
                    .truncationMode(.tail)
                    .frame(minWidth: 20)
                    .help(taskGroup.name)

                if !taskGroup.project.isEmpty, showProject {
                    Text("@\(taskGroup.project)")
                        .lineLimit(1)
                        .bold()
                        .opacity(0.626)
                        .frame(minWidth: 20)
                        .truncationMode(.tail)
                        .help(taskGroup.project)
                }

                if !taskGroup.tags.isEmpty, showTags {
                    Text(taskGroup.tags)
                        .lineLimit(1)
                        .opacity(0.626)
                        .frame(minWidth: 20)
                        .truncationMode(.middle)
                        .help(taskGroup.tags)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(showSeconds ? formatTimeShort(taskGroup.totalTime) : formatTimeLongWithoutSeconds(taskGroup.totalTime))
                    .monospacedDigit()
                if taskGroup.rate > 0 {
                    let amountEarned = (taskGroup.rate / 3600.0) * Double(taskGroup.totalTime)
                    Text(String(amountEarned.formatted(.currency(code: getCurrencyCode(for: chosenCurrency)))))
                        .opacity(0.626)
                        .monospacedDigit()
                }
            }
            
            #if os(macOS)
            Button {
                if !stopWatchHelper.isRunning {
                    var taskTextBuilder = "\(taskGroup.name)"
                    if !taskGroup.project.isEmpty {
                        taskTextBuilder += " @\(taskGroup.project)"
                    }
                    if !taskGroup.tags.isEmpty {
                        taskTextBuilder += " \(taskGroup.tags)"
                    }
                    if taskGroup.rate > 0.0 {
                        taskTextBuilder += " \(chosenCurrency)\(taskGroup.rate)"
                    }

                    TaskTagsInput.shared.text = taskTextBuilder
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
        .frame(height: 30)
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
