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
    
    init(entry1: String, entry2: String, entry3: String) {
        self.entry1 = entry1
        self.entry2 = entry2
        self.entry3 = entry3
    }
}

func saveGratitude(entry1: String, entry2: String, entry3: String, context: ModelContext) {
    let gratitude = DailyGratitude(entry1: entry1, entry2: entry2, entry3: entry3)
    context.insert(gratitude)
    try? context.save()
}


