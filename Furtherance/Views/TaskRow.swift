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
//                    contentView.repeatTask(taskTags: taskGroup.name + " " + taskGroup.tags)
                }
        }
        .frame(height: 25)
        .padding()
        .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
        .cornerRadius(20)
    }
}

//struct TaskRow_Previews: PreviewProvider {
//    static var previews: some View {
////        TaskRow(taskGroup: FurTaskGroup(task: FurTask(id: 0, name: "Task Name", startTime: Date.now, stopTime: Calendar.current.date(byAdding: .second, value: 5, to: Date.now)!, tags: "#tag1 #tag2")))
//        TaskRow(taskGroup: FurTaskGroup(task: FurTask()))
//    }
//}
