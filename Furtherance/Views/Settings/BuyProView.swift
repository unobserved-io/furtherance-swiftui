//
//  BuyProView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import StoreKit
import SwiftUI

struct BuyProView: View {
	@ObservedObject var storeModel = StoreModel.shared

	var body: some View {
		if storeModel.purchasedIds.isEmpty {
			if let product = storeModel.products.first {
				Section {
					Text("Unlock the Pro version to gain access to all features.")
						.multilineTextAlignment(.center)
						.frame(maxWidth: .infinity, alignment: .center)
						.italic()
					#if os(macOS)
						HStack {
							Button(action: {
								Task {
									if storeModel.purchasedIds.isEmpty {
										try await storeModel.purchase()
									}
								}
							}) {
								Text("Buy Pro \(product.displayPrice)")
							}
							.keyboardShortcut(.defaultAction)
							Button(action: {
								Task {
									try await AppStore.sync()
								}
							}) {
								Text("Restore Purchase")
							}
						}
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.bottom)
					#else
						Button(action: {
							Task {
								if storeModel.purchasedIds.isEmpty {
									try await storeModel.purchase()
								}
							}
						}) {
							Text("Buy Pro \(product.displayPrice)")
						}
						.keyboardShortcut(.defaultAction)
						Button(action: {
							Task {
								try await AppStore.sync()
							}
						}) {
							Text("Restore Purchase")
								.foregroundColor(.primary)
						}
					#endif
				}
			}
		}
	}
}

struct BuyProView_Previews: PreviewProvider {
	static var previews: some View {
		BuyProView()
	}
}
