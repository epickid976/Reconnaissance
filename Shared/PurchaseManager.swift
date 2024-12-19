//
//  PurchaseManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/19/24.
//

import StoreKit

@MainActor
final class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    @Published var products: [SKProduct] = []
    @Published var purchasedProductIdentifiers: Set<String> = []
    @Published var purchaseError: PurchaseError? = nil
    
    private let productIDs: [String] = [
        "SuperEco",
        "EcoPurchase",
        "ValuePurchase",
        "MaxPurchase",
        "UltimatePurchase"
    ]
    
    override private init() {
        super.init()
        SKPaymentQueue.default().add(self) // Observe transactions
        fetchProducts()
    }
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func purchase(_ product: SKProduct) async {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension PurchaseManager: SKProductsRequestDelegate {
    nonisolated func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    ) {
        DispatchQueue.main.async {
            self.products = response.products.sorted { $0.price.compare($1.price) == .orderedAscending }
        }
    }
}

extension PurchaseManager: @preconcurrency SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                purchasedProductIdentifiers.insert(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    DispatchQueue.main.async {
                        self.purchaseError = PurchaseError(message: error.localizedDescription)
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}

struct PurchaseError: Identifiable {
    let id = UUID() // Unique identifier
    let message: String
}
