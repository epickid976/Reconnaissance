//
//  GratitudeEntry.swift
//  ReconnaissanceApp
//
//  Created by Jose Blanco on 12/9/24.
//

import Foundation
import SwiftData
import WatchConnectivity

@Model
class DailyGratitude: @unchecked Sendable{
    var id: UUID = UUID() // Default value
    var date: Date = Date() // Default value
    var entry1: String = "" // Default value
    var entry2: String = "" // Default value
    var entry3: String = "" // Default value
    var streak: Int = 0 // Add a streak property
    var notes: String = "" // Add a notes property
    
    init(entry1: String, entry2: String, entry3: String, date: Date = Date(), notes: String) {
        self.entry1 = entry1
        self.entry2 = entry2
        self.entry3 = entry3
        self.date = date
        self.notes = notes
    }
    
    // Static Example Instance
    static let example = DailyGratitude(
        entry1: "Grateful for family support",
        entry2: "Thankful for a sunny day",
        entry3: "Appreciative of a productive work session",
        notes: "Had a great day today"
    )
    
    // Static Example for Yesterday
    static let exampleYesterday = DailyGratitude(
        entry1: "Happy about a good night's sleep",
        entry2: "Appreciative of delicious coffee",
        entry3: "Grateful for a walk in the park",
        notes: "Felt refreshed and ready to start the day"
    ).withDateAdjusted(by: -1)
    
    // Helper to adjust the date
    func withDateAdjusted(by days: Int) -> DailyGratitude {
        let adjusted = self
        adjusted.date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return adjusted
    }
}

extension DailyGratitude {
    
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(for: DailyGratitude.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let gratitude = DailyGratitude.example
        let yesterday = DailyGratitude.exampleYesterday
        let another = DailyGratitude(
            entry1: "Grateful for a good book",
            entry2: "Thankful for a warm meal",
            entry3: "Appreciative of a good night's sleep",
            date: Date().addingTimeInterval(-60 * 60 * 24 * 2),
            notes: "Had a great day today"
        )
        
        container.mainContext.insert(gratitude)
        calculateAndUpdateStreak(for: gratitude, in: container.mainContext)
        container.mainContext.insert(yesterday)
        calculateAndUpdateStreak(for: yesterday, in: container.mainContext)
        container.mainContext.insert(another)
        calculateAndUpdateStreak(for: another, in: container.mainContext)
        return container
    }
}

extension DailyGratitude {
    @MainActor
    static func calculateAndUpdateStreak(for entry: DailyGratitude, in context: ModelContext) {
        // Fetch all entries from the context and sort by date
        let allEntries = try! context.fetch(FetchDescriptor<DailyGratitude>())
            .sorted(by: { $0.date < $1.date })

        // Normalize dates to ensure time components are removed
        let normalizedEntries = allEntries.map { gratitude -> DailyGratitude in
            let normalizedGratitude = gratitude
            normalizedGratitude.date = Calendar.current.startOfDay(for: gratitude.date)
            return normalizedGratitude
        }

        // Find the index of the current entry
        guard let index = normalizedEntries.firstIndex(where: { $0.id == entry.id }) else { return }

        // Calculate the streak for the current entry
        let previousEntry = index > 0 ? normalizedEntries[index - 1] : nil
        if let previous = previousEntry {
            let difference = Calendar.current.dateComponents([.day], from: previous.date, to: entry.date).day ?? 0
            entry.streak = (difference == 1) ? previous.streak + 1 : 1
        } else {
            // No previous entry means streak starts at 1
            entry.streak = 1
        }

        // Update subsequent entries to propagate streak
        for i in (index + 1)..<normalizedEntries.count {
            let currentEntry = normalizedEntries[i]
            let previous = normalizedEntries[i - 1]
            let difference = Calendar.current.dateComponents([.day], from: previous.date, to: currentEntry.date).day ?? 0
            currentEntry.streak = (difference == 1) ? previous.streak + 1 : 1
            context.insert(currentEntry) // Insert updates the entry
        }

        // Insert (update) the current entry in the context
        context.insert(entry)
    }
}

func saveGratitude(entry1: String, entry2: String, entry3: String, notes: String, context: ModelContext) {
    let gratitude = DailyGratitude(entry1: entry1, entry2: entry2, entry3: entry3, notes: notes)
    context.insert(gratitude)
    try? context.save()
}

func calculateStreaks(for gratitudes: [DailyGratitude]) -> [DailyGratitude] {
    let sortedGratitudes = gratitudes.sorted(by: { $0.date < $1.date })
    var previousDate: Date? = nil
    var currentStreak = 0

    for gratitude in sortedGratitudes {
        if let previous = previousDate {
            // Calculate the difference in days
            let difference = Calendar.current.dateComponents([.day], from: previous, to: gratitude.date).day ?? 0
            if difference == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            // First entry starts a streak
            currentStreak = 1
        }
        gratitude.streak = currentStreak // Assign the streak
        previousDate = gratitude.date
    }

    return sortedGratitudes
}
