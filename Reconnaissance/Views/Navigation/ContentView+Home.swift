//
//  ContentView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData
import NavigationTransitions

//MARK: Content View - App Entry Point

struct ContentView: View {

    var body: some View {
        HomeTabView() // Your tab view becomes the root container
    }
}

//MARK: Home Tab View

struct HomeTabView: View {
    @State private var selectedTab = 0
    @State private var path = NavigationPath() // Shared path for navigation
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Tab Content
                if selectedTab == 0 {
                    GratitudeListView(path: $path)
                        .tag(0)
                } else if selectedTab == 1 {
                    NavigationStack {
                        VStack {
                            Text("Settings View Placeholder") // Placeholder
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                        .tag(2)
                        .navigationTitle("Settings View")
                        .navigationBarTitleDisplayMode(.large)
                    }
                }

                // Custom Tab Bar
                ZStack {
                    // Background with Rounded Corners at the Top
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.gray.opacity(0.2) // Softer gray for dark mode
                                : Color.white // Crisp white for light mode
                        )
                        .shadow(
                            color: colorScheme == .dark
                                ? .black.opacity(0.6) // Deeper shadow for dark mode
                                : .gray.opacity(0.2), // Lighter shadow for light mode
                            radius: 4,
                            x: 0,
                            y: -2
                        )
                        .ignoresSafeArea(.container, edges: .bottom) // Extends to the safe area
                    
                    HStack(alignment: .center) {
                        TabBarButton(
                            icon: selectedTab == 0 ? "house.fill" : "house",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 0
                            }
                        }
                        TabBarButton(
                            icon: selectedTab == 1 ? "gearshape.fill" : "gearshape",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40) // Tab bar height
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationDestination(for: GratitudeRoutes.self) { route in
                switch route {
                case .add:
                    AddGratitudeView()
                case .detail(let gratitude):
                    GratitudeDetailView(gratitude: gratitude)
                case .edit(let gratitude):
                    GratitudeEditView(gratitude: gratitude)
                case .homeList:
                    GratitudeListView(path: $path)
                }
            }
            .navigationTransition(.slide.combined(with: .fade(.in)))
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                action()
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(Color.gray)
                    )
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isSelected ? 10 : 0)) // Subtle rotation
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isSelected)
            }
        }
        .frame(maxWidth: .infinity)
        .hoverEffect(.lift)
    }
}

//MARK: - Preview

#Preview {
    ContentView()
}

struct GratitudeDetailView: View {
    
    let gratitude: DailyGratitude
    
    var body: some View {
        Text("Gratitude Details")
    }
}

struct GratitudeEditView: View {
    let gratitude: DailyGratitude
    
    var body: some View {
        Text("Edit Gratitude")
    }
}

struct AddGratitudeView: View {
    var body: some View {
        Text("Add Gratitude View")
    }
}




