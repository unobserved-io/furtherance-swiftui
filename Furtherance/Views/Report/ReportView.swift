//
//  ReportView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 22.07.2024.
//

import Charts
import SwiftUI

private enum GroupStatsBy {
	case days
	case weeks
	case months
	case years
}

struct ReportView: View {
	static let titleToChartSpacing: CGFloat? = 20
	static let chartFrameHeight: CGFloat? = 300

    @FetchRequest(
        entity: FurTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FurTask.startTime, ascending: false)],
        predicate: NSPredicate(format: "(startTime >= %@) AND (startTime <= %@)", (Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: Date.now)) ?? Date.now) as NSDate, Date.now as NSDate),
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

	@State var rangeStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date.now.startOfDay) ?? Date.now
	@State var rangeEndDate: Date = .now.endOfDay
    @State private var timeframe: Timeframe = .thirtyDays
	@State private var rangeIsEmpty: Bool = false
	@State private var groupingType: GroupStatsBy = .days
	@State private var groupedTaskData: [GroupOfTasksByTime] = []

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
						newStartDate = rangeStartDate
						newStopDate = rangeEndDate
                    }
					tasksInTimeframe.nsPredicate = NSPredicate(format: "(startTime >= %@) AND (startTime <= %@)", newStartDate as NSDate, newStopDate as NSDate)
					rangeStartDate = newStartDate
					rangeEndDate = newStopDate
                }
                
                if timeframe == .custom {
                    HStack {
                        DatePicker(
                            selection: $rangeStartDate,
							in: Date(
								timeIntervalSinceReferenceDate: 0
							) ... rangeEndDate,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .labelsHidden()
                        .onChange(of: rangeStartDate) { _, newStartDate in
							rangeStartDate = newStartDate.startOfDay
							tasksInTimeframe.nsPredicate = NSPredicate(format: "(startTime >= %@) AND (startTime <= %@)", rangeStartDate as NSDate, rangeEndDate as NSDate)
                        }
                        Text("to")
                        DatePicker(
                            selection: $rangeEndDate,
                            in: rangeStartDate ... Date.now.endOfDay,
                            displayedComponents: [.date],
                            label: {}
                        )
                        .frame(minHeight: 35)
                        .labelsHidden()
                        .onChange(of: rangeEndDate) { _, newStopDate in
							rangeEndDate = newStopDate.endOfDay
							tasksInTimeframe.nsPredicate = NSPredicate(
								format: "(startTime >= %@) AND (startTime <= %@)",
								rangeStartDate as NSDate,
								rangeEndDate as NSDate
							)
                        }
                    }
                }
            }
            .padding()
			
			Divider().padding(.bottom)

			if !tasksInTimeframe.isEmpty {
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

				VStack(spacing: Self.titleToChartSpacing) {
					Text("Earnings")
					Chart {
						ForEach(groupedTaskData) { taskGroup in
							LineMark(
								x: .value("Date", taskGroup.readableDate),
								y: .value("Earnings", taskGroup.earnings)
							)
						}
						//				if let selectedEarningsDate {
						//					RectangleMark(x: .value("Date", selectedEarningsDate))
						//						.foregroundStyle(.blue.opacity(0.2))
						//						.annotation(position: .overlay, alignment: .center, spacing: 0) {
						//							Text(selectedEarningsAmount, format: .currency(code: "USD"))
						//								.rotationEffect(.degrees(-90))
						//								.frame(width: chartFrameHeight)
						//						}
						//				}
					}
					.chartYAxis {
						AxisMarks(position: .leading) {
							let value = $0.as(Int.self)! // Using Int removes cents
							AxisValueLabel {
								Text("$\(value)")
							}
							AxisGridLine()
						}
					}
					//			.chartOverlay { proxy in
					//				GeometryReader { geometry in
					//					ZStack(alignment: .top) {
					//						Rectangle().fill(.clear).contentShape(Rectangle())
					//#if os(macOS)
					//							.onContinuousHover { hoverPhase in
					//								switch hoverPhase {
					//								case .active(let hoverLocation):
					//									updateSelectedEarningsOnHover(at: hoverLocation.x, proxy: proxy)
					//								case .ended:
					//									selectedEarningsDate = nil
					//								}
					//							}
					//#else
					//							.onTapGesture { location in
					//								updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
					//							}
					//#endif
					//					}
					//				}
					//			}
					.frame(height: Self.chartFrameHeight)
				}
				.task(id: tasksInTimeframe.count) {
					processAllData()
				}
				.onAppear {
					processAllData()
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

	private func processAllData() {
		groupedTaskData = []
		groupingType = decideGroupingType()
		groupedTaskData = groupTaskData()
	}

	private func decideGroupingType() -> GroupStatsBy {
		// TODO: This can be based on number of days in the tasksInTimeFrame instead of total days in range
		let calendar = Calendar.current
		let numberOfDaysInRange = (
			calendar
				.dateComponents(
					[.day],
					from: tasksInTimeframe.last?.startTime ?? .distantPast,
					to: tasksInTimeframe.first?.startTime ?? .distantFuture
				).day ?? 0
		) + 1
		if numberOfDaysInRange <= 31 {
			return .days
		} else if numberOfDaysInRange <= 62 {
			return .weeks
		} else if numberOfDaysInRange <= 731 {
			return .months
		} else {
			return .years
		}
	}

	private func groupTaskData() -> [GroupOfTasksByTime] {
		var timeGroups: [GroupOfTasksByTime] = []
		for task in tasksInTimeframe {
			switch groupingType {
			case .days:
				if let matchingGroup = timeGroups
					.first(
						where: { Calendar.current.isDate(
							task.startTime ?? .distantPast,
							inSameDayAs: $0.date
						)
						})
				{
					matchingGroup.add(task)
				} else {
					let dayFormatter: DateFormatter = {
						let localFormat = DateFormatter
							.dateFormat(
								fromTemplate: "MMdd",
								options: 0,
								locale: Locale.current
							)
						let formatter = DateFormatter()
						formatter.dateFormat = localFormat
						return formatter
					}()
					let readableDate = dayFormatter.string(from: task.startTime ?? .now)
					timeGroups.append(GroupOfTasksByTime(
						from: task,
						readableDate: readableDate
					))
				}
			case .weeks:
				if let matchingGroup = timeGroups
					.first(
						where: { Calendar.current.isDate(
							task.startTime ?? .distantPast,
							equalTo: $0.date,
							toGranularity: .weekOfYear
						)
						})
				{
					matchingGroup.add(task)
				} else {
					let weekOfYear = Calendar.current.component(
						.weekOfYear,
						from: task.startTime ?? .distantPast
					)
					let readableDate = "Wk \(weekOfYear)"
					timeGroups.append(GroupOfTasksByTime(
						from: task,
						readableDate: readableDate
					))
				}
			case .months:
				if let matchingGroup = timeGroups
					.first(
						where: { Calendar.current.isDate(
							task.startTime ?? .distantPast,
							equalTo: $0.date,
							toGranularity: .month
						)
						})
				{
					matchingGroup.add(task)
				} else {
					// Month should be Mar '23 if there are some months not 2023
					let dayFormatter: DateFormatter = {
						let localFormat = DateFormatter
							.dateFormat(
								fromTemplate: "MMM",
								options: 0,
								locale: Locale.current
							)
						let formatter = DateFormatter()
						formatter.dateFormat = localFormat
						return formatter
					}()
					let readableDate = dayFormatter.string(from: task.startTime ?? .now)
					timeGroups.append(GroupOfTasksByTime(
						from: task,
						readableDate: readableDate
					))
				}
			case .years:
				if let matchingGroup = timeGroups
					.first(
						where: { Calendar.current.isDate(
							task.startTime ?? .distantPast,
							equalTo: $0.date,
							toGranularity: .year
						)
						})
				{
					matchingGroup.add(task)
				} else {
					let year = Calendar.current.component(
						.year,
						from: task.startTime ?? .distantPast
					)
					let readableDate = String(year)
					timeGroups.append(GroupOfTasksByTime(
						from: task,
						readableDate: readableDate
					))
				}
			}
		}
		return timeGroups
	}

	private func getComponentType() -> Calendar.Component {
		switch groupingType {
		case .days:
			return .day
		case .weeks:
			return .weekOfYear
		case .months:
			return .month
		case .years:
			return .year
		}
	}

	//	private func updateSelectedEarningsOnHover(at location: CGFloat, proxy: ChartProxy) {
	//		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
	//			return
	//		}
	//		if let selectedDayData = dayDataInRange.first(where: { String($0.grouping) == userDateSelection }) {
	//			selectedEarningsAmount = selectedDayData.earned
	//		}
	//		selectedEarningsDate = userDateSelection
	//	}
}

class GroupOfTasksByTime: Identifiable {
	var time: Int
	var earnings: Double
	var date: Date
	var readableDate: String
	var numberOfTasks: Int = 1
	var id = UUID()

	init(from task: FurTask, readableDate: String) {
		self.time = (Calendar.current.dateComponents([.second], from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now).second ?? 0)
		if task.rate > 0 {
			self.earnings = (task.rate / 3600.0) * Double(self.time)
		} else {
			self.earnings = 0.0
		}
		self.date = task.startTime ?? .now
		self.readableDate = readableDate
	}

	func add(_ task: FurTask) {
		let totalTaskTime = (Calendar.current.dateComponents([.second], from: task.startTime ?? Date.now, to: task.stopTime ?? Date.now).second ?? 0)
		time += totalTaskTime
		if task.rate > 0 {
			earnings += (task.rate / 3600.0) * Double(totalTaskTime)
		}
		numberOfTasks += 1
	}
}

#Preview {
    ReportView()
}
