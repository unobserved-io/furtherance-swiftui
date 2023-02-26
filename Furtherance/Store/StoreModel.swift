//
//  Store.swift
//  furtherance
//
//  Created by Ricky Kresslein on 2/19/23.
//

import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

class StoreModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedIds: [String] = []
    
    var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func fetchProducts() async throws {
        /// Get all user's purchased products
        do {
            let products = try await Product.products(for: ["pro"])
            DispatchQueue.main.async {
                self.products = products
            }
            
            if let product = products.first {
                await isPurchased(product: product)
            }
        } catch {
            print("Error fetching products: \(error)")
        }
    }
    
    func isPurchased(product: Product) async {
        /// Check if product has already been purchased
        guard let state = await product.currentEntitlement else { return }
        switch state {
        case .verified(let transaction):
            DispatchQueue.main.async {
                self.purchasedIds.append(transaction.productID)
            }
        case .unverified:
            break
        }
    }

    func purchase() async throws {
        /// Run when user tries to purchase a product
        guard let product = products.first else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                // Transaction will be verified for automatically using JWT(jwsRepresentation) - we can check the result
                let transaction = try checkVerified(verificationResult)
                
                // the transaction is verified, deliver the content to the user
                await updateProductStatus()
                
                // always finish a transaction - performance
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Error purchasing: \(error)")
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        /// Check verification results
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        /// Listen for App Store transactions, such as an approval for an "Ask to buy"
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    @MainActor
    func updateProductStatus() async {
        /// Update user's purchased items
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let _ = products.first(where: { $0.id == transaction.productID }) {
                    DispatchQueue.main.async {
                        self.purchasedIds.append(transaction.productID)
                    }
                }
            } catch {
                print("Transaction failed verification")
            }
        }
    }
}
