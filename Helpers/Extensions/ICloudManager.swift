//
//  AppFileManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/16/24.
//

import Foundation
import SwiftUI


final class ICloudManager: Sendable {
    static let shared = ICloudManager()
    
    private let directoryName = "Reconnaissance" // Replace with your app's directory name
    
    private init() {}
    
    // MARK: - Get iCloud Directory
    func getICloudDirectory() -> URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            print("iCloud is not available.")
            return nil
        }
        
        let appDirectoryURL = containerURL.appendingPathComponent("Documents").appendingPathComponent(directoryName, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            print("Directory ensured at: \(appDirectoryURL)")
        } catch {
            print("Failed to create iCloud directory: \(error)")
            return nil
        }
        
        return appDirectoryURL
    }
    
    // MARK: - Upload File
    func uploadFile(named fileName: String, contents: Data) async -> Bool {
        guard let directoryURL = getICloudDirectory() else {
            print("iCloud directory not available.")
            return false
        }
        
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        do {
            try contents.write(to: fileURL)
            print("File uploaded to: \(fileURL)")
            return true
        } catch {
            print("Failed to upload file: \(error)")
            return false
        }
    }
    
    // MARK: - List Files in Directory
    func listFiles() -> [URL]? {
        guard let directoryURL = getICloudDirectory() else { return nil }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            return files
        } catch {
            print("Failed to list files: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete File
    func deleteFile(named fileName: String, completion: @escaping (Bool) -> Void) {
        guard let directoryURL = getICloudDirectory() else {
            completion(false)
            return
        }
        
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("File deleted: \(fileURL)")
            completion(true)
        } catch {
            print("Failed to delete file: \(error)")
            completion(false)
        }
    }
    
    // MARK: - Check if iCloud is Available
    func isICloudAvailable() -> Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
}


