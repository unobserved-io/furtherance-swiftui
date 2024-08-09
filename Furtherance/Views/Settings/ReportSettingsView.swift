//
//  ReportSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 26.07.2024.
//

import SwiftUI

struct ReportSettingsView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(PassStatusModel.self) var passStatusModel: PassStatusModel

	@ObservedObject var storeModel = StoreModel.shared

	@AppStorage("showTotalEarnings") private var showTotalEarnings = true
	@AppStorage("showTotalEarningsChart") private var showTotalEarningsChart = true
	@AppStorage("showTotalTimeChart") private var showTotalTimeChart = true
	@AppStorage("showAvgEarnedPerTaskChart") private var showAvgEarnedPerTaskChart = true
	@AppStorage("showAvgTimePerTaskChart") private var showAvgTimePerTaskChart = true
	@AppStorage("showBreakdownBySelection") private var showBreakdownBySelection = true
	@AppStorage("showSelectionByTimeChart") private var showSelectionByTimeChart = true
	@AppStorage("showSelectionByEarningsChart") private var showSelectionByEarningsChart = true
	@AppStorage("showSelectionEarnings") private var showSelectionEarnings = true

	var body: some View {
		ScrollView {
			Form {
				Section(header: TextWithBadge("Toggle Charts")) {
					HStack {
						Toggle("Total Earnings", isOn: $showTotalEarnings)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Total Earnings Chart", isOn: $showTotalEarningsChart)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Total Time Chart", isOn: $showTotalTimeChart)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Average Earned Per Task", isOn: $showAvgEarnedPerTaskChart)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Average Time Per Task", isOn: $showAvgTimePerTaskChart)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Breakdown By Selection Section", isOn: $showBreakdownBySelection)
							.disabled(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Selection Earnings", isOn: $showSelectionEarnings)
							.disabled(
								(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty) || !showBreakdownBySelection
							)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Selection By Time Chart", isOn: $showSelectionByTimeChart)
							.disabled(
								(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty) || !showBreakdownBySelection
							)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Selection By Earnings Chart", isOn: $showSelectionByEarningsChart)
							.disabled(
								(passStatusModel.passStatus == .notSubscribed && storeModel.purchasedIds.isEmpty) || !showBreakdownBySelection
							)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()
				}
			}
			#if os(macOS)
			.padding(20)
			#endif
		}
	}
}

#Preview {
	ReportSettingsView()
}
