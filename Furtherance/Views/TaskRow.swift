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

    func formatTime(totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
        let minutes = (totalSeconds % 3600) / 60
        let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
        let seconds = totalSeconds % 60
        let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
        return hoursString + ":" + minutesString + ":" + secondsString
    }

    var body: some View {
        HStack(alignment: .center) {
            taskGroup.tasks.count == 1 ? nil : Image(systemName: taskGroup.tasks.count <= 50 ? "\(taskGroup.tasks.count).circle.fill" : "ellipsis.circle.fill").foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(taskGroup.name)
                    .fontWeight(.bold)
                    .truncationMode(.tail)
                    .frame(minWidth: 20)

                if !taskGroup.tags.isEmpty {
                    Text(taskGroup.tags)
                        .opacity(0.626)
                        .frame(minWidth: 20)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Text(formatTime(totalSeconds: taskGroup.totalTime))
            Image(systemName: "arrow.counterclockwise.circle")
                .contentShape(Circle())
                .onTapGesture {
                    let taskTagsInput = TaskTagsInput.sharedInstance
                    taskTagsInput.text = taskGroup.name + " " + taskGroup.tags
                    StopWatch.sharedInstance.start()
                    TimerHelper.sharedInstance.onStart(nameAndTags: taskTagsInput.text)
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
