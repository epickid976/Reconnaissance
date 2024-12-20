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
    @Published var isProUser: Bool = false
    @Published var purchaseError: PurchaseError? = nil
    
    private let productIDs: [String] = [
        "SuperEco",
        "EcoPurchase",
        "ValuePurchase",
        "MaxPurchase",
        "UltimatePurchase"
    ]
    
    var purchasedProductIdentifiers: Set<String> = []

    override private init() {
        super.init()
        SKPaymentQueue.default().add(self) // Observe transactions
        loadPurchasedProducts()
        fetchProducts()
    }
    
    // MARK: - Public Methods
    
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
    
    // MARK: - Private Methods
    
    private func loadPurchasedProducts() {
        // Load purchase state from UserDefaults
        let savedIdentifiers = UserDefaults.standard.stringArray(forKey: "purchasedProducts") ?? []
        purchasedProductIdentifiers = Set(savedIdentifiers)
        isProUser = !purchasedProductIdentifiers.isEmpty
    }
    
    private func savePurchasedProduct(_ identifier: String) {
        // Save new purchase to UserDefaults
        purchasedProductIdentifiers.insert(identifier)
        var savedIdentifiers = UserDefaults.standard.stringArray(forKey: "purchasedProducts") ?? []
        if !savedIdentifiers.contains(identifier) {
            savedIdentifiers.append(identifier)
            UserDefaults.standard.set(savedIdentifiers, forKey: "purchasedProducts")
        }
        isProUser = !purchasedProductIdentifiers.isEmpty
    }
}

// MARK: - SKProductsRequestDelegate
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

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: @preconcurrency SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                savePurchasedProduct(transaction.payment.productIdentifier)
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
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // Called after all restore transactions are processed
        var savedIdentifiers = UserDefaults.standard.stringArray(forKey: "purchasedProducts") ?? []
        for identifier in purchasedProductIdentifiers {
            if !savedIdentifiers.contains(identifier) {
                savedIdentifiers.append(identifier)
            }
        }
        UserDefaults.standard.set(savedIdentifiers, forKey: "purchasedProducts")
        isProUser = !savedIdentifiers.isEmpty
    }
}

// MARK: - Error Handling
struct PurchaseError: Identifiable {
    let id = UUID()
    let message: String
}
