//
//  ProSubscribeView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 09.08.2024.
//

import StoreKit
import SwiftUI

struct ProSubscribeView: View {
	@Binding var navSelection: NavItems?

	@Environment(PassStatusModel.self) var passStatusModel: PassStatusModel
	@Environment(\.passIDs) private var passIDs

	var body: some View {
		ScrollView {
			SubscriptionStoreView(groupID: passIDs.group) {
				VStack {
					Text("Pro")
						.font(.largeTitle)
						.foregroundStyle(.accent)
						.bold()
						.padding(.bottom)

					VStack(alignment: .listRowSeparatorLeading, spacing: 12.0) {
						// Idle detection
						HStack {
							Image(systemName: "cursorarrow.motionlines")
								.font(.system(size: 38))
								.foregroundStyle(.accent)
							VStack(alignment: .leading) {
								Text("Idle Detection")
									.bold()
								Text("When you forget to stop the timer")
									.font(.caption)
							}
						}

						// Charts
						HStack {
							Image(systemName: "chart.xyaxis.line")
								.font(.system(size: 38))
								.foregroundStyle(.accent)
							VStack(alignment: .leading) {
								Text("Charts")
									.bold()
								Text("Visualize where your time goes")
									.font(.caption)
							}
						}

						// Shortcuts
						HStack {
							Image(systemName: "hare.fill")
								.font(.system(size: 35))
								.foregroundStyle(.accent)
							VStack(alignment: .leading) {
								Text("Shortcuts")
									.bold()
								Text("Quickly time common tasks")
									.font(.caption)
							}
						}

						// Import/Export
						HStack {
							Image(systemName: "doc.on.doc.fill")
								.font(.system(size: 38))
								.foregroundStyle(.accent)
							VStack(alignment: .leading) {
								Text("Backup & Restore")
									.bold()
								Text("Import and export data")
									.font(.caption)
							}
						}

						// Settings
						HStack {
							Image(systemName: "gearshape.fill")
								.font(.system(size: 38))
								.foregroundStyle(.accent)
							VStack(alignment: .leading) {
								Text("Settings")
									.bold()
								Text("Access all pro settings")
									.font(.caption)
							}
						}
					}
				}
			}
			.padding(10)
			.storeButton(.visible, for: .restorePurchases)
			.storeButton(.hidden, for: .cancellation) // X at top right
			.subscriptionStoreControlStyle(.buttons)
			.subscriptionStoreButtonLabel(.action)
			.subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, for: .termsOfService)
			.subscriptionStorePolicyDestination(url: URL(string: "https://unobserved.io/privacy")!, for: .privacyPolicy)
			.onInAppPurchaseCompletion { _, result in
				if case .success(.success(_)) = result {
					navSelection = .timer
				}
			}
		}
	}
}

#Preview {
	ProSubscribeView(navSelection: .constant(.buyPro))
}
