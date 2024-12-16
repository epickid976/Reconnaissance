//
//  AppFileManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/16/24.
//

import Foundation
import SwiftUI

@MainActor
final class AppFileManager: Sendable {
    static let shared = AppFileManager()
    
    // Your app's iCloud container identifier
    // Replace "iCloud.com.yourcompany.yourappname" with your actual container ID
    private let iCloudContainerIdentifier = "iCloud.com.jbdevelopment.appreconnaissance"
    
    // Get the iCloud container URL for your specific app
    func getAppICloudContainerURL() -> URL? {
        return FileManager.default.url(
            forUbiquityContainerIdentifier: iCloudContainerIdentifier
        )?.appendingPathComponent("Documents")
    }
    
    // Save item to app's iCloud container
    func saveToiCloudContainer(item: Item) -> Bool {
        guard let containerURL = getAppICloudContainerURL() else {
            print("iCloud container not available")
            return false
        }
        
        do {
            // Ensure documents directory exists
            try FileManager.default.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Generate a unique filename
            let filename = "\(UUID().uuidString)_\(item.name)"
            let destinationURL = containerURL.appendingPathComponent(filename)
            
            // Save based on item type
            switch item.type {
            case .document, .image:
                guard let sourceURL = item.dataURL else {
                    print("No source URL for file")
                    return false
                }
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                
            case .text:
                guard let textData = item.text?.data(using: .utf8) else {
                    print("No text content to save")
                    return false
                }
                try textData.write(to: destinationURL)
            }
            
            return true
        } catch {
            print("Error saving to iCloud container: \(error.localizedDescription)")
            return false
        }
    }
    
    // Check if iCloud is available for your app
    func isICloudAvailable() -> Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
}
