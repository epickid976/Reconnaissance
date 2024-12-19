//
//  PaywallView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/19/24.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var currentCardIndex: Int = 0 // Track the current card/page index
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon
                Image("appstore")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.top, 20)
                
                // Title and Subtitle
                VStack(spacing: 10) {
                    Text("Unlock Spaces")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Support my gratitude journal by choosing a tier below. Your contribution helps keep this app alive!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if UIScreen.main.bounds.width <= 375 {
                    // Paginated Cards for Smaller Screens
                    ZStack {
                        ForEach(Array(purchaseManager.products.enumerated()), id: \.offset) {
                            index,
                            product in
                            HStack {
                                // Left Chevron
                                Button(action: {
                                    if currentCardIndex > 0 {
                                        withAnimation(.spring()) {
                                            currentCardIndex -= 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(currentCardIndex > 0 ? .white : Color(UIColor.lightGray)
                                        )
                                        .frame(width: 30, height: 50)
                                        .contentShape(Rectangle())
                                        .opacity(currentCardIndex > 0 ? 1.0 : 0.3)  // Adjust opacity based on availability
                                }
                                .disabled(currentCardIndex == 0)
                                
                                // Card View
                                paywallCard(for: product)
                                    .id(index)
                                    .offset(x: CGFloat(index - currentCardIndex) * UIScreen.main.bounds.width)
                                    .animation(.spring(), value: currentCardIndex)
                                
                                // Right Chevron
                                Button(action: {
                                    if currentCardIndex < purchaseManager.products.count - 1 {
                                        withAnimation(.spring()) {
                                            currentCardIndex += 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(
                                            currentCardIndex < purchaseManager.products.count - 1 ? .white : Color(UIColor.lightGray)
                                        )
                                        .frame(width: 30, height: 50)
                                        .contentShape(Rectangle())
                                        .opacity(currentCardIndex < purchaseManager.products.count - 1 ? 1.0 : 0.3)  // Adjust opacity based on availability
                                }
                                .disabled(currentCardIndex == purchaseManager.products.count - 1)
                            }
                        }
                    }
                    .frame(height: 200)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 && currentCardIndex < purchaseManager.products.count - 1 {
                                    withAnimation(.spring()) {
                                        currentCardIndex += 1
                                    }
                                } else if value.translation.width > 50 && currentCardIndex > 0 {
                                    withAnimation(.spring()) {
                                        currentCardIndex -= 1
                                    }
                                }
                            }
                    )
                } else {
                    // Vertical Stack for Larger Screens
                    VStack(spacing: 16) {
                        ForEach(purchaseManager.products, id: \.productIdentifier) { product in
                            purchaseOption(for: product)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Restore Purchases Button
                Button(action: {
                    purchaseManager.restorePurchases()
                }) {
                    Text("Restore Purchases")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.95))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .padding(.vertical)
        }
        .onAppear {
            Task {
                purchaseManager.fetchProducts()
            }
        }
        .alert(item: $purchaseManager.purchaseError) { error in
            Alert(
                title: Text("Purchase Failed"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Card View for Smaller Screens
    @ViewBuilder
    private func paywallCard(for product: SKProduct) -> some View {
        VStack(spacing: 20) {
            Text(product.localizedTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Button(action: {
                Task {
                    await PurchaseManager.shared.purchase(product)
                    if purchaseManager.purchaseError == nil {
                        dismiss() // Dismiss the paywall if purchase is successful
                    }
                }
            }) {
                Text(product.priceFormatted)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(15)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Purchase Option for Larger Screens
    @ViewBuilder
    private func purchaseOption(for product: SKProduct) -> some View {
        Button(action: {
            Task {
                await PurchaseManager.shared.purchase(product)
                if purchaseManager.purchaseError == nil {
                    dismiss() // Dismiss the paywall if purchase is successful
                }
            }
        }) {
            HStack {
                Text(product.localizedTitle)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(product.priceFormatted)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            )
        }
    }
}

extension SKProduct {
    var priceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "$\(price)"
    }
}

struct PurchaseOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var purchases = PurchaseManager.shared.products
    @State private var purchasedIdentifiers = PurchaseManager.shared.purchasedProductIdentifiers
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(purchases, id: \.productIdentifier) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(product.localizedTitle)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(product.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if purchasedIdentifiers.contains(product.productIdentifier) {
                                // Purchased Badge
                                Text("Purchased")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.2))
                                    )
                            } else {
                                // Buy Button
                                Button(action: {
                                    Task {
                                        await PurchaseManager.shared.purchase(product)
                                        purchasedIdentifiers = PurchaseManager.shared.purchasedProductIdentifiers
                                    }
                                }) {
                                    Text("Buy")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(8)
                                }
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondarySystemBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Purchases")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss() // SwiftUI's built-in dismiss action
                    }
                }
            }
        }
        .onAppear {
            purchases = PurchaseManager.shared.products
            purchasedIdentifiers = PurchaseManager.shared.purchasedProductIdentifiers
        }
    }
}
#Preview("Paywall") {
    PaywallView()
}
#Preview("Overview") {
    PurchaseOverviewView()
}

