//
//  ContentView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData
import NavigationTransitions
import Toasts

//MARK: Content View - App Entry Point

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    
    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                
                SecureView()
                    .onOpenURL { url in
                        if url.scheme == "reconnaissance" && url.host == "addGratitude" {
                            Task {
                                await CentrePopup_AddGratitudeEntry(
                                    modelContext: modelContext
                                ) {
                                    ConfettiController.showConfettiOverlay()
                                }
                                .present()
                            }
                        }
                    }
            } else {
                OnboardingView()
            }
        }.animation(.spring(), value: hasSeenOnboarding)
    }
    
    //MARK: - Debug Methods
    private func deleteAllEntities() {
        do {
            let fetchDescriptor = FetchDescriptor<DailyGratitude>()
            let allEntities = try modelContext.fetch(fetchDescriptor)
            for entity in allEntities {
                modelContext.delete(entity)
            }
            try modelContext.save()
            print("All entities deleted.")
        } catch {
            print("Error deleting entities: \(error)")
        }
    }
    
    private func addEntitiesForPastYear() {
        let calendar = Calendar.current
        let today = Date()
        
        for daysAgo in 0..<365 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let gratitude = DailyGratitude(
                    entry1: "Grateful for day \(daysAgo + 1)",
                    entry2: "Entry 2",
                    entry3: "Entry 3",
                    date: date,
                    notes: "Notes for day \(daysAgo + 1)"
                )
                modelContext.insert(gratitude)
                DailyGratitude.calculateAndUpdateStreak(
                    for: gratitude,
                    in: modelContext
                )
            }
        }
        
        do {
            try modelContext.save()
            print("Entities for the past year added.")
        } catch {
            print("Error saving entities: \(error)")
        }
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
                        .installToast(position: .bottom)
                        .tag(0)
                } else if selectedTab == 1 {
                    SpacesView()
                        .installToast(position: .bottom)
                        .tag(1)
                } else if selectedTab == 2 {
                    SettingsView()
                        .installToast(position: .bottom)
                        .tag(2)
                }
                
                // Custom Tab Bar
                ZStack {
                    // Background with Rounded Corners at the Top
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            colorScheme == .dark
                            ? Material.thick // Softer gray for dark mode
                            : Material.thick // Crisp white for light mode
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
                                HapticManager.shared.trigger(.lightImpact)
                                selectedTab = 0
                            }
                        }
                        TabBarButton(
                            icon: selectedTab == 1 ? "square.split.2x2.fill" : "square.split.2x2",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.spring()) {
                                HapticManager.shared.trigger(.lightImpact)
                                selectedTab = 1
                            }
                        }
                        
                        TabBarButton(
                            icon: selectedTab == 2 ? "gearshape.fill" : "gearshape",
                            isSelected: selectedTab == 2
                        ) {
                            withAnimation(.spring()) {
                                HapticManager.shared.trigger(.lightImpact)
                                selectedTab = 2
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




