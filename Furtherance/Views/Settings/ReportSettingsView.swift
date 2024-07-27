//
//  ReportSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 26.07.2024.
//

import SwiftUI

struct ReportSettingsView: View {
	@ObservedObject var storeModel = StoreModel.shared
	@Environment(\.colorScheme) var colorScheme

	@AppStorage("showTotalEarnings") private var showTotalEarnings = true
	@AppStorage("showTotalEarningsChart") private var showTotalEarningsChart = true
	@AppStorage("showTotalTimeChart") private var showTotalTimeChart = true
	@AppStorage("showAvgEarnedPerTaskChart") private var showAvgEarnedPerTaskChart = true
	@AppStorage("showAvgTimePerTaskChart") private var showAvgTimePerTaskChart = true
	@AppStorage("showBreakdownBySelection") private var showBreakdownBySelection = true
	@AppStorage("showSelectionByTimeChart") private var showSelectionByTimeChart = true
	@AppStorage("showSelectionByEarningsChart") private var showSelectionByEarningsChart = true

	var body: some View {
		ScrollView {
			Form {
				BuyProView()

				Section(header: TextWithBadge("Toggle Charts")) {
					HStack {
						Toggle("Total Earnings", isOn: $showTotalEarnings)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Total Earnings Chart", isOn: $showTotalEarningsChart)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Total Time Chart", isOn: $showTotalTimeChart)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Average Earned Per Task", isOn: $showAvgEarnedPerTaskChart)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Average Time Per Task", isOn: $showAvgTimePerTaskChart)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Breakdown By Selection Section", isOn: $showBreakdownBySelection)
							.disabled(storeModel.purchasedIds.isEmpty)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Selection By Time", isOn: $showSelectionByTimeChart)
							.disabled(
								storeModel.purchasedIds.isEmpty || !showBreakdownBySelection
							)
					}
					.frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
					.padding()

					HStack {
						Toggle("Selection By Earnings", isOn: $showSelectionByEarningsChart)
							.disabled(
								storeModel.purchasedIds.isEmpty || !showBreakdownBySelection
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
