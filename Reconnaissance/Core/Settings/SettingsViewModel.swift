//
//  SettingsViewModel.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/13/24.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var presentPolicy = false
    
    func deleteAllData(modelContext: ModelContext) async {
        Task {
            do {
                let fetchDescriptor = FetchDescriptor<DailyGratitude>() // Replace `DailyGratitude` with your model name
                let allEntries = try modelContext.fetch(fetchDescriptor)
                
                allEntries.forEach { modelContext.delete($0) }
                
                try modelContext.save()
            } catch {
                print("Error deleting all data: \(error.localizedDescription)")
            }
        }
    }
    
    func exportDataAsJSON(data: [DailyGratitude]) async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)

            // Create a file URL
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DailyGratitudes.json")

            // Write the JSON data to a temporary file
            try jsonData.write(to: tempURL)

            // Share the file using UIActivityViewController
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                    rootVC.present(activityVC, animated: true, completion: nil)
                }
            }
        } catch {
            print("Error exporting data as JSON: \(error.localizedDescription)")
        }
    }
    
    func exportDataAsCSV(data: [DailyGratitude]) async {
        var csvString = "ID,Date,Entry1,Entry2,Entry3,Notes\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for item in data {
            let formattedDate = dateFormatter.string(from: item.date)
            let line = "\(item.id.uuidString),\(formattedDate),\"\(escapeForCSV(item.entry1))\",\"\(escapeForCSV(item.entry2))\",\"\(escapeForCSV(item.entry3))\",\"\(escapeForCSV(item.notes))\"\n"
            csvString.append(line)
        }
        
        print("Generated CSV:\n\(csvString)") // Debugging

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DailyGratitudes.csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            print("CSV file written to:", tempURL) // Debugging

            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                    rootVC.present(activityVC, animated: true, completion: nil)
                }
            }
        } catch {
            print("Error exporting data as CSV: \(error.localizedDescription)")
        }
    }

    // Helper to escape CSV values
    func escapeForCSV(_ value: String) -> String {
        var escapedValue = value
        escapedValue = escapedValue.replacingOccurrences(of: "\"", with: "\"\"")
        if escapedValue.contains(",") || escapedValue.contains("\"") || escapedValue.contains("\n") {
            escapedValue = "\"\(escapedValue)\""
        }
        return escapedValue
    }
    
    func importDataFromJSON(fileURL: URL, modelContext: ModelContext) async {
        do {
            // Request access to the file
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("Error: Couldn't access the file URL.")
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() } // Ensure access is stopped when done

            // Read the JSON data from the file
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode the JSON into an array of `DailyGratitude`
            let importedData = try decoder.decode([DailyGratitude].self, from: jsonData)

            for item in importedData {
                // Check if an entry for the same day exists
                let existingEntries = try  modelContext.fetch(FetchDescriptor<DailyGratitude>()).filter {
                    Calendar.current.isDate($0.date, inSameDayAs: item.date)
                }
                
                // If no entry exists, insert the new item
                if existingEntries.isEmpty {
                    modelContext.insert(item)
                    DailyGratitude.calculateAndUpdateStreak(for: item, in: modelContext)
                }
            }

            // Save the context
            try modelContext.save()
            print("Successfully imported \(importedData.count) items from JSON.")
        } catch {
            print("Error importing data from JSON: \(error.localizedDescription)")
        }
    }

    func importDataFromCSV(fileURL: URL, modelContext: ModelContext) async {
        do {
            // Request access to the file
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("Error: Couldn't access the file URL.")
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() } // Ensure access is stopped when done

            // Read the CSV data from the file
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = csvData.split(separator: "\n").dropFirst() // Skip the header row

            for row in rows {
                let columns = row.split(separator: ",").map { $0.replacingOccurrences(of: "\"", with: "") }
                if columns.count >= 6 {
                    let entryDate = ISO8601DateFormatter().date(from: columns[1]) ?? Date()
                    
                    // Check if an entry for the same day exists
                    let existingEntries = try modelContext.fetch(FetchDescriptor<DailyGratitude>()).filter {
                        Calendar.current.isDate($0.date, inSameDayAs: entryDate)
                    }
                    
                    // If no entry exists, insert the new item
                    if existingEntries.isEmpty {
                        let gratitude = DailyGratitude(
                            entry1: columns[2],
                            entry2: columns[3],
                            entry3: columns[4],
                            date: entryDate,
                            notes: columns[5]
                        )
                        modelContext.insert(gratitude)
                        DailyGratitude.calculateAndUpdateStreak(for: gratitude, in: modelContext)
                    }
                }
            }

            // Save the context
            try modelContext.save()
            print("Successfully imported data from CSV.")
        } catch {
            print("Error importing data from CSV: \(error.localizedDescription)")
        }
    }
}


