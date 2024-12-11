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
class DailyGratitude {
    var id: UUID = UUID() // Default value
    var date: Date = Date() // Default value
    var entry1: String = "" // Default value
    var entry2: String = "" // Default value
    var entry3: String = "" // Default value
    var streak: Int = 0 // Add a streak property
    var notes: String = "" // Add a notes property
    
    init(entry1: String, entry2: String, entry3: String, notes: String) {
        self.entry1 = entry1
        self.entry2 = entry2
        self.entry3 = entry3
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
        var adjusted = self
        adjusted.date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return adjusted
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
