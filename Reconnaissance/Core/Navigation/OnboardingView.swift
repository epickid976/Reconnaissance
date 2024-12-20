//
//  OnboardingView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/19/24.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    
    private let onboardingData = [
        OnboardingItem(
            title: NSLocalizedString("Welcome to Gratitude!", comment: ""),
            description: NSLocalizedString("Reflect on your day and jot down three things you're grateful for.", comment: ""),
            imageName: "sun.max",
            gradient: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
        ),
        OnboardingItem(
            title: NSLocalizedString("Track Your History", comment: ""),
            description: NSLocalizedString("See all your past entries and relive your moments of gratitude.", comment: ""),
            imageName: "calendar",
            gradient: [Color.green.opacity(0.3), Color.teal.opacity(0.3)]
        ),
        OnboardingItem(
            title: NSLocalizedString("Unlock Spaces", comment: ""),
            description: NSLocalizedString("Create Spaces to organize images, documents, and items that make you feel better.", comment: ""),
            imageName: "folder",
            gradient: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]
        ),
        OnboardingItem(
            title: NSLocalizedString("Widgets for Quick Access", comment: ""),
            description: NSLocalizedString("Add widgets to your home screen for easy journaling.", comment: ""),
            imageName: "rectangle.stack",
            gradient: [Color.cyan.opacity(0.3), Color.indigo.opacity(0.3)]
        ),
        OnboardingItem(
            title: NSLocalizedString("Sync Across Devices", comment: ""),
            description: NSLocalizedString("All your data syncs securely through iCloud.", comment: ""),
            imageName: "icloud",
            gradient: [Color.yellow.opacity(0.3), Color.blue.opacity(0.3)]
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            SmoothGradientBackground(gradients: onboardingData.map { $0.gradient }, currentPage: $currentPage)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(item: onboardingData[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .padding()
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact) // Optional Haptic Feedback
                    if currentPage < onboardingData.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                        dismiss()
                    }
                }) {
                    Text(currentPage < onboardingData.count - 1 ? NSLocalizedString("Next", comment: "") : NSLocalizedString("Get Started", comment: ""))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue.opacity(0.1)) // Subtle tint
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

struct OnboardingItem {
    let title: String
    let description: String
    let imageName: String
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let item: OnboardingItem
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: item.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(item.gradient.first ?? .blue)
                .padding(.top, 40)
            
            Text(item.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(item.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct SmoothGradientBackground: View {
    let gradients: [[Color]]
    @Binding var currentPage: Int
    
    var body: some View {
        ZStack {
            ForEach(gradients.indices, id: \.self) { index in
                if index == currentPage {
                    LinearGradient(
                        colors: gradients[index],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(1)
                    .animation(.easeInOut(duration: 0.8), value: currentPage)
                }
            }
        }
    }
}
