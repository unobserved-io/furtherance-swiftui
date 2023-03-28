//
//  TaskRow.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import SwiftUI

struct TaskRow: View {
    var taskGroup: FurTaskGroup
    @Environment(\.colorScheme) var colorScheme

    init(taskGroup: FurTaskGroup) {
        self.taskGroup = taskGroup
    }

    var body: some View {
        HStack(alignment: .center) {
            taskGroup.tasks.count == 1 ? nil : Image(systemName: taskGroup.tasks.count <= 50 ? "\(taskGroup.tasks.count).circle.fill" : "ellipsis.circle.fill").foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(taskGroup.name)
                    .fontWeight(.bold)
                    .truncationMode(.tail)
                    .frame(minWidth: 20)
                    .help(taskGroup.name)

                if !taskGroup.tags.isEmpty {
                    Text(taskGroup.tags)
                        .opacity(0.626)
                        .frame(minWidth: 20)
                        .truncationMode(.middle)
                        .help(taskGroup.tags)
                }
            }

            Spacer()

            Text(formatTimeShort(taskGroup.totalTime))
                .font(.system(.body).monospacedDigit())
            Image(systemName: "arrow.counterclockwise.circle")
                .contentShape(Circle())
                .onTapGesture {
                    if !StopWatch.sharedInstance.isRunning {
                        let taskTagsInput = TaskTagsInput.sharedInstance
                        taskTagsInput.text = taskGroup.name + " " + taskGroup.tags
                        StopWatch.sharedInstance.start()
                        TimerHelper.sharedInstance.onStart(nameAndTags: taskTagsInput.text)
                    }
                }
        }
        .frame(height: 25)
        .padding()
        .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
        .cornerRadius(20)
    }
}

struct TaskRow_Previews: PreviewProvider {
    static var previews: some View {
        TaskRow(taskGroup: FurTaskGroup(task: FurTask()))
    }
}
