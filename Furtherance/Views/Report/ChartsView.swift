//
//  ReportView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 22.07.2024.
//

import Charts
import SwiftUI

struct ChartsView: View {
	static let titleToChartSpacing: CGFloat? = 30
	static let chartFrameHeight: CGFloat? = 300

	@ObservedObject var storeModel = StoreModel.shared

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

	private enum GroupStatsBy {
		case days
		case weeks
		case months
		case years
	}

	private enum TaskAttributes: String, Hashable, CaseIterable, Identifiable {
		case title
		case project
		case tags
		case rate

		var id: Self { self }
	}

	@AppStorage("chosenCurrency") private var chosenCurrency: String = "$"
	@AppStorage("showTotalEarnings") private var showTotalEarnings = true
	@AppStorage("showTotalEarningsChart") private var showTotalEarningsChart = true
	@AppStorage("showTotalTimeChart") private var showTotalTimeChart = true
	@AppStorage("showAvgEarnedPerTaskChart") private var showAvgEarnedPerTaskChart = true
	@AppStorage("showAvgTimePerTaskChart") private var showAvgTimePerTaskChart = true
	@AppStorage("showBreakdownBySelection") private var showBreakdownBySelection = true
	@AppStorage("showSelectionByTimeChart") private var showSelectionByTimeChart = true
	@AppStorage("showSelectionByEarningsChart") private var showSelectionByEarningsChart = true

	@State var rangeStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date.now.startOfDay) ?? Date.now
	@State var rangeEndDate: Date = .now.endOfDay

	@State private var timeframe: Timeframe = .thirtyDays
	@State private var rangeIsEmpty: Bool = false
	@State private var groupingType: GroupStatsBy = .days
	@State private var groupedTaskData: [GroupOfTasksByTime] = []
	@State private var groupedSelectedTaskData: [GroupOfTasksByTime] = []
	@State private var selectedEarningsDate: String?
	@State private var selectedEarningsAmount: Double = 0.0
	@State private var selectedTimeDate: String?
	@State private var selectedTimeAmount: Int = 0
	@State private var averageTimeDate: String?
	@State private var averageTimeAmount: Int = 0
	@State private var averageEarningsDate: String?
	@State private var averageEarningsAmount: Double = 0.0
	@State private var timeDateForSelectedTask: String?
	@State private var timeForSelectedTask: Int = 0
	@State private var earningsDateForSelectedTask: String?
	@State private var earningsForSelectedTask: Double = 0
	@State private var selectedTaskAttribute: TaskAttributes = .title
	@State private var selectedTask: String = ""
	@State private var matchingTasksByAttribute: Set<String> = []

	private let hmsFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.maximumUnitCount = 3
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.day, .hour, .minute, .second]
		return formatter
	}()

	var body: some View {
		if !storeModel.purchasedIds.isEmpty {
			ScrollView {
				VStack(spacing: 20) {
					// MARK: Date range selector

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
								newStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: newStartDate) ?? Date.now).date ?? Date.now
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
						// MARK: Total time and earnings in range

						HStack {
							VStack {
								VStack {
									HStack(alignment: .lastTextBaseline) {
										Text(getTotalTime())
											.font(.system(size: 55))
											.foregroundStyle(.accent)
									}
									Text("Total time")
										.font(.title2)
								}
								.frame(maxWidth: .infinity)
								.padding()
							}
							.background(.accent.opacity(0.2))
							.clipShape(RoundedRectangle(cornerRadius: 15))
							.frame(alignment: .center)

							if showTotalEarnings {
								VStack {
									VStack {
										HStack(alignment: .lastTextBaseline) {
											Text(getTotalEarnings(), format: .currency(code: getCurrencyCode(for: chosenCurrency)))
												.font(.system(size: 55))
												.foregroundStyle(.accent)
										}
										Text("Earned")
											.font(.title2)
									}
									.frame(maxWidth: .infinity)
									.padding()
								}
								.background(.accent.opacity(0.2))
								.clipShape(RoundedRectangle(cornerRadius: 15))
								.frame(alignment: .center)
							}
						}

						if groupedTaskData.contains(where: { $0.earnings > 0 }) && showTotalEarningsChart {
							// MARK: Total earnings chart
							VStack(spacing: Self.titleToChartSpacing) {
								Text("Earnings")
									.font(.title)
								Chart {
									ForEach(groupedTaskData) { taskGroup in
										if groupedTaskData.count > 1 {
											LineMark(
												x: .value("Date", taskGroup.readableDate),
												y: .value("Earnings", taskGroup.earnings)
											)
										} else {
											BarMark(
												x: .value("Date", taskGroup.readableDate),
												y: .value("Earnings", taskGroup.earnings)
											)
										}
									}
									if let selectedEarningsDate {
										RectangleMark(x: .value("Date", selectedEarningsDate))
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(
													selectedEarningsAmount, format:
													.currency(
														code: getCurrencyCode(
															for: chosenCurrency
														)
													)
												)
												.rotationEffect(.degrees(-90))
												.frame(width: Self.chartFrameHeight)
											}
									}
								}
								.chartYAxis {
									AxisMarks(position: .leading) {
										let value = $0.as(Int.self)! // Using Int removes cents
										AxisValueLabel {
											Text("\(chosenCurrency)\(value)")
										}
										AxisGridLine()
									}
								}
								.chartOverlay { proxy in
									GeometryReader { geometry in
										ZStack(alignment: .top) {
											Rectangle().fill(.clear).contentShape(Rectangle())
											#if os(macOS)
												.onContinuousHover { hoverPhase in
													switch hoverPhase {
													case .active(let hoverLocation):
														updateSelectedEarningsOnHover(at: hoverLocation.x, proxy: proxy)
													case .ended:
														selectedEarningsDate = nil
													}
												}
											#else
												.onTapGesture { location in
														updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
													}
											#endif
										}
									}
								}
								.frame(height: Self.chartFrameHeight)
							}
						}

						// MARK: Total time chart

						if showTotalTimeChart {
							VStack(spacing: Self.titleToChartSpacing) {
								Text("Time")
									.font(.title)
								Chart {
									ForEach(groupedTaskData) { taskGroup in
										if groupedTaskData.count > 1 {
											LineMark(
												x: .value("Date", taskGroup.readableDate),
												y: .value("Minutes", taskGroup.time)
											)
										} else {
											BarMark(
												x: .value("Date", taskGroup.readableDate),
												y: .value("Minutes", taskGroup.time)
											)
										}
									}
									if let selectedTimeDate {
										RectangleMark(x: .value("Date", selectedTimeDate))
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(formatTimeShort(selectedTimeAmount))
													.rotationEffect(.degrees(-90))
													.frame(width: Self.chartFrameHeight)
											}
									}
								}
								.chartYAxis {
									AxisMarks(position: .leading) {
										let value = $0.as(Int.self)!
										AxisValueLabel {
											Text("\(formatTimeShort(value))")
										}
										AxisGridLine()
									}
								}
								.chartOverlay { proxy in
									GeometryReader { geometry in
										ZStack(alignment: .top) {
											Rectangle().fill(.clear).contentShape(Rectangle())
											#if os(macOS)
												.onContinuousHover { hoverPhase in
													switch hoverPhase {
													case .active(let hoverLocation):
														updateSelectedTimeOnHover(at: hoverLocation.x, proxy: proxy)
													case .ended:
														selectedTimeDate = nil
													}
												}
											#else
												.onTapGesture { location in
														updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
													}
											#endif
										}
									}
								}
								.frame(height: Self.chartFrameHeight)
							}
						}

						// MARK: Average earnings per task

						if groupedTaskData.contains(where: { $0.earnings > 0 }) && showAvgEarnedPerTaskChart {
							VStack(spacing: Self.titleToChartSpacing) {
								Text("Average earned per task")
									.font(.title)
								Chart {
									ForEach(groupedTaskData) { taskGroup in
										if groupedTaskData.count > 1 {
											LineMark(
												x: .value("Date", taskGroup.readableDate),
												y:
												.value(
													"Earnings",
													taskGroup.earnings / Double(taskGroup.numberOfTasks)
												)
											)
										} else {
											BarMark(
												x: .value("Date", taskGroup.readableDate),
												y:
												.value(
													"Earnings",
													taskGroup.earnings / Double(taskGroup.numberOfTasks)
												)
											)
										}
									}
									if let averageEarningsDate {
										RectangleMark(x: .value("Date", averageEarningsDate))
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(
													averageEarningsAmount, format:
													.currency(
														code: getCurrencyCode(
															for: chosenCurrency
														)
													)
												)
												.rotationEffect(.degrees(-90))
												.frame(width: Self.chartFrameHeight)
											}
									}
								}
								.chartYAxis {
									AxisMarks(position: .leading) {
										let value = $0.as(Int.self)!
										AxisValueLabel {
											Text("\(chosenCurrency)\(value)")
										}
										AxisGridLine()
									}
								}
								.chartOverlay { proxy in
									GeometryReader { geometry in
										ZStack(alignment: .top) {
											Rectangle().fill(.clear).contentShape(Rectangle())
											#if os(macOS)
												.onContinuousHover { hoverPhase in
													switch hoverPhase {
													case .active(let hoverLocation):
														updateAverageEarningsOnHover(at: hoverLocation.x, proxy: proxy)
													case .ended:
														averageEarningsDate = nil
													}
												}
											#else
												.onTapGesture { location in
														updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
													}
											#endif
										}
									}
								}
								.frame(height: Self.chartFrameHeight)
							}
						}

						// MARK: Average time per task

						if showAvgTimePerTaskChart {
							VStack(spacing: Self.titleToChartSpacing) {
								Text("Average time per task")
									.font(.title)
								Chart {
									ForEach(groupedTaskData) { taskGroup in
										if groupedTaskData.count > 1 {
											LineMark(
												x: .value("Date", taskGroup.readableDate),
												y:
												.value(
													"Minutes",
													taskGroup.time / taskGroup.numberOfTasks
												)
											)
										} else {
											BarMark(
												x: .value("Date", taskGroup.readableDate),
												y:
												.value(
													"Minutes",
													taskGroup.time / taskGroup.numberOfTasks
												)
											)
										}
									}
									if let averageTimeDate {
										RectangleMark(x: .value("Date", averageTimeDate))
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(formatTimeShort(averageTimeAmount))
													.rotationEffect(.degrees(-90))
													.frame(width: Self.chartFrameHeight)
											}
									}
								}
								.chartYAxis {
									AxisMarks(position: .leading) {
										let value = $0.as(Int.self)!
										AxisValueLabel {
											Text("\(formatTimeShort(value))")
										}
										AxisGridLine()
									}
								}
								.chartOverlay { proxy in
									GeometryReader { geometry in
										ZStack(alignment: .top) {
											Rectangle().fill(.clear).contentShape(Rectangle())
											#if os(macOS)
												.onContinuousHover { hoverPhase in
													switch hoverPhase {
													case .active(let hoverLocation):
														updateAverageTimeOnHover(at: hoverLocation.x, proxy: proxy)
													case .ended:
														averageTimeDate = nil
													}
												}
											#else
												.onTapGesture { location in
														updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
													}
											#endif
										}
									}
								}
								.frame(height: Self.chartFrameHeight)
							}
						}

						if showBreakdownBySelection && (showSelectionByTimeChart || showSelectionByEarningsChart) {
							// MARK: Charts by selection

							Divider()

							VStack(spacing: Self.titleToChartSpacing) {
								Text("Breakdown By Selection")
									.font(.largeTitle)

								HStack {
									Picker(
										"Time by selection",
										selection: $selectedTaskAttribute
									) {
										ForEach(TaskAttributes.allCases) { taskAttribute in
											Text(taskAttribute.rawValue.capitalized)
										}
									}
									.labelsHidden()
									.onChange(of: selectedTaskAttribute) {
										getAllMatchingAttributesForTime()
									}

									Picker(
										"Time by selection",
										selection: $selectedTask
									) {
										ForEach(Array(matchingTasksByAttribute), id: \.self) { attribute in
											Text(
												selectedTaskAttribute == .project ? attribute.localizedCapitalized : attribute)
										}
									}
									.labelsHidden()
									.onChange(of: selectedTask) {
										getDataForSelectedTaskForTime()
									}
								}

								if showSelectionByTimeChart {
									Text("Selection By Time")
										.font(.title)
									Chart {
										ForEach(groupedSelectedTaskData) { taskGroup in
											// Use a bar chart when there isn't enough data for a good line chart
											if groupedSelectedTaskData.count > 2 {
												LineMark(
													x: .value("Date", taskGroup.readableDate),
													y: .value("Minutes", taskGroup.time)
												)
											} else {
												BarMark(
													x: .value("Date", taskGroup.readableDate),
													y: .value("Minutes", taskGroup.time)
												)
											}
										}
										if let timeDateForSelectedTask {
											RectangleMark(
												x:
												.value(
													"Date",
													timeDateForSelectedTask
												)
											)
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(
													formatTimeShort(
														timeForSelectedTask
													)
												)
												.rotationEffect(.degrees(-90))
												.frame(width: Self.chartFrameHeight)
											}
										}
									}
									.chartYAxis {
										AxisMarks(position: .leading) {
											let value = $0.as(Int.self)!
											AxisValueLabel {
												Text("\(formatTimeShort(value))")
											}
											AxisGridLine()
										}
									}
									.chartOverlay { proxy in
										GeometryReader { geometry in
											ZStack(alignment: .top) {
												Rectangle().fill(.clear).contentShape(Rectangle())
												#if os(macOS)
													.onContinuousHover { hoverPhase in
														switch hoverPhase {
														case .active(let hoverLocation):
															updateSelectedTimeForSelectedTaskOnHover(at: hoverLocation.x, proxy: proxy)
														case .ended:
															timeDateForSelectedTask = nil
														}
													}
												#else
													.onTapGesture { location in
															updateSelectedEarningsOnTap(at: location, proxy: proxy, geometry: geometry)
														}
												#endif
											}
										}
									}
									.frame(height: Self.chartFrameHeight)
								}

								if groupedSelectedTaskData
									.contains(where: { $0.earnings > 0 }) && showSelectionByEarningsChart
								{
									Text("Selection By Earnings")
										.font(.title)
									Chart {
										ForEach(groupedSelectedTaskData) { taskGroup in
											// Use a bar chart when there isn't enough data for a good line chart
											if groupedSelectedTaskData.count > 2 {
												LineMark(
													x: .value("Date", taskGroup.readableDate),
													y: .value("Minutes", taskGroup.earnings)
												)
											} else {
												BarMark(
													x: .value("Date", taskGroup.readableDate),
													y: .value("Minutes", taskGroup.earnings)
												)
											}
										}
										if let earningsDateForSelectedTask {
											RectangleMark(
												x:
												.value(
													"Date",
													earningsDateForSelectedTask
												)
											)
											.foregroundStyle(.accent.opacity(0.2))
											.annotation(position: .overlay, alignment: .center, spacing: 0) {
												Text(
													earningsForSelectedTask,
													format:
													.currency(
														code: getCurrencyCode(
															for: chosenCurrency
														)
													)
												)
												.rotationEffect(.degrees(-90))
												.frame(width: Self.chartFrameHeight)
											}
										}
									}
									.chartYAxis {
										AxisMarks(position: .leading) {
											let value = $0.as(Int.self)! // Using Int removes cents
											AxisValueLabel {
												Text("\(chosenCurrency)\(value)")
											}
											AxisGridLine()
										}
									}
									.chartOverlay { proxy in
										GeometryReader { geometry in
											ZStack(alignment: .top) {
												Rectangle().fill(.clear).contentShape(Rectangle())
												#if os(macOS)
													.onContinuousHover { hoverPhase in
														switch hoverPhase {
														case .active(let hoverLocation):
															updateEarningsForSelectedTaskOnHover(at: hoverLocation.x, proxy: proxy)
														case .ended:
															earningsDateForSelectedTask = nil
														}
													}
												#else
													.onTapGesture { location in
															updateEarningsForSelectedTaskOnHover(at: location, proxy: proxy, geometry: geometry)
														}
												#endif
											}
										}
									}
									.frame(height: Self.chartFrameHeight)
								}
							}
						}
					}
				}
				.padding(10)
			}
			.task(id: tasksInTimeframe.count) {
				processAllData()
			}
			.onAppear {
				processAllData()
				getAllMatchingAttributesForTime()
			}
		} else {
			Spacer()
			ContentUnavailableView {
				Label("Pro Only", image: "chart.line.slash")
			} description: {
				Text("Charts are only available in the pro version. The \"List\" report is free.")
			}
			Spacer()
		}
	}

	private func getTotalTime() -> String {
		var totalTaskTime = DateComponents()
		totalTaskTime.second = 0
		totalTaskTime.second? += tasksInTimeframe.map {
			Calendar.current.dateComponents([.second], from: $0.startTime ?? .distantPast, to: $0.stopTime ?? .distantFuture).second ?? 0
		}.reduce(0,+)
		return hmsFormatter.string(from: totalTaskTime) ?? "00:00"
	}

	private func getTotalEarnings() -> Double {
		var totalEarnings = 0.0
		totalEarnings += tasksInTimeframe.map {
			($0.rate / 3600.0) * Double(Calendar.current.dateComponents([.second], from: $0.startTime ?? .distantPast, to: $0.stopTime ?? .distantFuture).second ?? 0)
		}.reduce(0,+)
		return totalEarnings
	}

	private func processAllData() {
		groupedTaskData = []
		groupingType = decideGroupingType()
		groupedTaskData = groupTaskData(from: Array(tasksInTimeframe))
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

	private func groupTaskData(from tasksToGroup: [FurTask]) -> [GroupOfTasksByTime] {
		var timeGroups: [GroupOfTasksByTime] = []
		for task in tasksToGroup {
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
		return timeGroups.reversed()
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

	private func updateSelectedEarningsOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			selectedEarningsAmount = selectedDayData.earnings
		}
		selectedEarningsDate = userDateSelection
	}

	private func updateSelectedTimeOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			selectedTimeAmount = selectedDayData.time
		}
		selectedTimeDate = userDateSelection
	}

	private func updateAverageTimeOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			averageTimeAmount = selectedDayData.time / selectedDayData.numberOfTasks
		}
		averageTimeDate = userDateSelection
	}

	private func updateAverageEarningsOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			averageEarningsAmount = selectedDayData.earnings / Double(selectedDayData.numberOfTasks)
		}
		averageEarningsDate = userDateSelection
	}

	private func updateSelectedTimeForSelectedTaskOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedSelectedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			timeForSelectedTask = selectedDayData.time
		}
		timeDateForSelectedTask = userDateSelection
	}

	private func updateEarningsForSelectedTaskOnHover(at location: CGFloat, proxy: ChartProxy) {
		guard let userDateSelection: String = proxy.value(atX: location, as: String.self) else {
			return
		}
		if let selectedDayData = groupedSelectedTaskData.first(
			where: { String($0.readableDate) == userDateSelection
			})
		{
			earningsForSelectedTask = selectedDayData.earnings
		}
		earningsDateForSelectedTask = userDateSelection
	}

	private func getAllMatchingAttributesForTime() {
		switch selectedTaskAttribute {
		case .title:
			matchingTasksByAttribute = Set(tasksInTimeframe.map { $0.name ?? "" }).filter { !$0.isEmpty }
		case .project:
			matchingTasksByAttribute = Set(
				tasksInTimeframe.map { $0.project?.lowercased() ?? ""
				})
			.filter { !$0.isEmpty }
		case .tags:
			matchingTasksByAttribute = Set(tasksInTimeframe.map { $0.tags ?? "" }).filter { !$0.isEmpty }
		case .rate:
			matchingTasksByAttribute = Set(tasksInTimeframe.map { String($0.rate) }).filter { !$0.isEmpty }
		}
		selectedTask = matchingTasksByAttribute.first ?? ""
	}

	private func getDataForSelectedTaskForTime() {
		groupedSelectedTaskData = groupTaskData(
			from: tasksInTimeframe.filter {
				switch selectedTaskAttribute {
				case .title:
					$0.name == selectedTask
				case .project:
					$0.project?.lowercased() == selectedTask.lowercased()
				case .tags:
					$0.tags == selectedTask
				case .rate:
					String($0.rate) == selectedTask
				}
			})
	}
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
			self.earnings = (task.rate / 3600.0) * Double(time)
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
	ChartsView()
}
