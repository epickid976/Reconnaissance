//
//  TodayView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/14/24.
//

import SwiftUI
import SwiftData

//MARK: - Today View

struct TodayView: View {
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query var gratitudes: [DailyGratitude]
    
    var today: DailyGratitude? {
        gratitudes.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        })
    }
    
    @State private var isShowingAddView: Bool = false
    @State private var isShowingEditView: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                VStack {
                    // Custom Header
                    headerView()
                    
                    if let today {
                        GratitudeCell(
                            gratitude: today,
                            mainWindowSize: proxy.size,
                            isAppleWatch: true
                        )
                        .padding()
                        .transition(.scale) // Animate appearance/disappearance
                    } else {
                        Button(action: {
                            HapticManager.shared.trigger(.impact)
                            isShowingAddView = true
                        }) {
                            VStack {
                                Text("No entry for today")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Tap to add.")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                            )
                            .transition(.opacity) // Animate appearance/disappearance
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                }
                .vSpacing(.top)
                .animation(.easeInOut, value: today) // Trigger animation when `today` changes
                .sheet(isPresented: $isShowingAddView) {
                    AddGratitudeView()
                }
            }
        }
    }
    
    //MARK: - Header View
    
    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Text("Today")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            if let today {
                // Edit Button
                NavigationLink(destination: AddGratitudeView(gratitude: today)) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.2)))
                }
                .onTapHaptic(.impact)
                .buttonStyle(.plain)
                
                // Delete Button
                Button(action: {
                    HapticManager.shared.trigger(.impact)
                    deleteEntry(today)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Circle().fill(Color.red.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
            
            
        }
    }
    
    private func deleteEntry(_ entry: DailyGratitude) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
            HapticManager.shared.trigger(.success)
        }
    }
}

//MARK: - Add / Edit Gratitude View

struct AddGratitudeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var entry1: String
    @State private var entry2: String
    @State private var entry3: String
    @State private var notes: String
    @State private var showError: Bool = false
    
    var gratitude: DailyGratitude? // Optional gratitude object for editing
    
    init(gratitude: DailyGratitude? = nil) {
        self.gratitude = gratitude
        _entry1 = State(initialValue: gratitude?.entry1 ?? "")
        _entry2 = State(initialValue: gratitude?.entry2 ?? "")
        _entry3 = State(initialValue: gratitude?.entry3 ?? "")
        _notes = State(initialValue: gratitude?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(gratitude == nil ? "Add Entry" : "Edit Entry")
                        .font(.headline)
                    
                    // Styled Text Fields
                    gratitudeField(placeholder: "Gratitude 1", text: $entry1)
                    gratitudeField(placeholder: "Gratitude 2", text: $entry2)
                    gratitudeField(placeholder: "Gratitude 3", text: $entry3)
                    gratitudeField(placeholder: "Notes (Optional)", text: $notes)
                    
                    // Save Button
                    Button(action: saveGratitudeEntry) {
                        Text(gratitude == nil ? "Save" : "Update")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(entry1.isEmpty || entry2.isEmpty || entry3.isEmpty)
                    
                    if showError {
                        Text("All fields are required!")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func gratitudeField(placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: text)
                .padding(8)
        }
    }
    
    private func saveGratitudeEntry() {
        HapticManager.shared.trigger(.impact)
        
        guard !entry1.isEmpty, !entry2.isEmpty, !entry3.isEmpty else {
            showError = true
            HapticManager.shared.trigger(.error)
            return
        }
        
        if let gratitude = gratitude {
            // Update existing gratitude entry
            gratitude.entry1 = entry1
            gratitude.entry2 = entry2
            gratitude.entry3 = entry3
            gratitude.notes = notes
        } else {
            // Add new gratitude entry
            let newEntry = DailyGratitude(
                entry1: entry1,
                entry2: entry2,
                entry3: entry3,
                date: Date(),
                notes: notes
            )
            modelContext.insert(newEntry)
            DailyGratitude.calculateAndUpdateStreak(for: newEntry, in: modelContext)
        }
        
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

//MARK: - Custom Animation

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

//MARK: - Preview

#Preview("Today") {
    TodayView()
}
