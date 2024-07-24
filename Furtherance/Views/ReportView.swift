//
//  ReportView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 22.07.2024.
//

import SwiftUI

struct ReportView: View {
    @FetchRequest(
        entity: FurTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        predicate: NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", (Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: Date.now)) ?? Date.now) as NSDate, Date.now as NSDate),
        animation: .default
    )
    var tasksInTimeframe: FetchedResults<FurTask>

    private enum Timeframe {
        case thisWeek
        case lastWeek
        case past7Days
        case thisMonth
        case lastMonth
        case thirtyDays
        case oneEightyDays
        case year
        case allTime
        case custom
    }

	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"

    @State private var timeframe: Timeframe = .thirtyDays
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date.now.startOfDay) ?? Date.now
    @State private var customStopDate: Date = .now.endOfDay
    
    var body: some View {
        VStack(spacing: 5) {
            VStack {
                Picker("Timeframe", selection: $timeframe) {
                    Text("This week").tag(Timeframe.thisWeek)
                    Text("Last week").tag(Timeframe.lastWeek)
                    Text("Past 7 days").tag(Timeframe.past7Days)
                    Text("This month").tag(Timeframe.thisMonth)
                    Text("Last month").tag(Timeframe.lastMonth)
                    Text("Past 30 days").tag(Timeframe.thirtyDays)
                    Text("Past 180 days").tag(Timeframe.oneEightyDays)
                    Text("Past year").tag(Timeframe.year)
                    Text("All time").tag(Timeframe.allTime)
                    Text("Date range").tag(Timeframe.custom)
                }
                .onChange(of: timeframe) { _, newTimeframe in
                    var newStartDate = Calendar.current.startOfDay(for: Date.now)
                    var newStopDate = Date.now
                    switch newTimeframe {
                    case .thisWeek:
                        newStartDate = newStartDate.startOfWeek
                    case .lastWeek:
                        newStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: (Calendar.current.date(byAdding: .weekOfYear, value: -1, to: newStartDate) ?? Date.now)).date ?? Date.now
                        newStopDate = newStartDate.endOfWeek
                    case .past7Days:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -6, to: newStartDate) ?? Date.now
                    case .thisMonth:
                        newStartDate = Date.now.startOfMonth
                    case .lastMonth:
                        let endOfLastMonth = Calendar.current.date(byAdding: .day, value: -1, to: Date.now.startOfMonth) ?? Date.now
                        newStartDate = endOfLastMonth.startOfMonth
                        newStopDate = newStartDate.endOfMonth
                    case .thirtyDays:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -29, to: newStartDate) ?? Date.now
                    case .oneEightyDays:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -179, to: newStartDate) ?? Date.now
                    case .year:
                        newStartDate = Calendar.current.date(byAdding: .day, value: -364, to: newStartDate) ?? Date.now
                    case .allTime:
                        newStartDate = Date(timeIntervalSince1970: 0)
                    case .custom:
                        newStartDate = customStartDate
                        newStopDate = customStopDate
                    }
					tasksInTimeframe.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", newStartDate as NSDate, newStopDate as NSDate)
                }
                
                if timeframe == .custom {
                    HStack {
                        DatePicker(
                            selection: $customStartDate,
                            in: Date(timeIntervalSinceReferenceDate: 0) ... customStopDate,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .labelsHidden()
                        .onChange(of: customStartDate) { _, newStartDate in
                            customStartDate = newStartDate.startOfDay
							tasksInTimeframe.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", customStartDate as NSDate, customStopDate as NSDate)
                        }
                        Text("to")
                        DatePicker(
                            selection: $customStopDate,
                            in: customStartDate ... Date.now.endOfDay,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .frame(minHeight: 35)
                        .labelsHidden()
                        .onChange(of: customStopDate) { _, newStopDate in
                            customStopDate = newStopDate.endOfDay
							tasksInTimeframe.nsPredicate = NSPredicate(format: "(startTime > %@) AND (startTime <= %@)", customStartDate as NSDate, customStopDate as NSDate)
                        }
                    }
                }
            }
            .padding()
			
			Divider().padding(.bottom)

			HStack {
				Text("Total time: \(formatTimeLong(getTotalTime()))")
					.font(Font.monospacedDigit(.system(.body))())
					.bold()
				HStack {
					Text("Total earnings: ")
						.font(Font.monospacedDigit(.system(.body))())
						.bold()
					Text(getTotalEarnings(), format: .currency(code: getCurrencyCode(for: chosenCurrency)))
				}
			}
        }
    }

	private func getTotalTime() -> Int {
		var totalTaskTime = 0
		totalTaskTime += tasksInTimeframe.map {
			Calendar.current.dateComponents([.second], from: $0.startTime ?? .distantPast, to: $0.stopTime ?? .distantFuture).second ?? 0
		}.reduce(0,+)
		return totalTaskTime
	}

	private func getTotalEarnings() -> Double {
		var totalEarnings: Double = 0.0
		totalEarnings += tasksInTimeframe.map {
			($0.rate / 3600.0) * Double(Calendar.current.dateComponents([.second], from: $0.startTime ?? .distantPast, to: $0.stopTime ?? .distantFuture).second ?? 0)
		}.reduce(0,+)
		return totalEarnings
	}
}

#Preview {
    ReportView()
}
