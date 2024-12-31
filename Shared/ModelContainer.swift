//
//  ModelContainer.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/31/24.
//

import SwiftData
import Foundation

struct SharedModelContainer {
    static let container: ModelContainer = {
        do {
            guard let documentsURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first else {
                fatalError("Unable to locate documents directory")
            }
            
            return try ModelContainer(
                for: DailyGratitude.self, SpaceCategory.self, Item.self,
                configurations: ModelConfiguration(
                    schema: nil, // Use default schema
                    url: documentsURL.appendingPathComponent("DailyGratitude.sqlite"), // Persistent store location
                    allowsSave: true, // Enable saving to the store
                    cloudKitDatabase: .automatic // Use automatic iCloud database selection
                )
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }()
}
