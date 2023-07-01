//
//  BuyProView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI
import StoreKit

struct BuyProView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    
    var body: some View {
        if storeModel.purchasedIds.isEmpty {
            if let product = storeModel.products.first {
                Text("Unlock the Pro version to gain access to all features.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
                    .italic()
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
            }
        }
    }
}

struct BuyProView_Previews: PreviewProvider {
    static var previews: some View {
        BuyProView()
    }
}
