//
//  AppVersionHelpers.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/12/24.
//

import Foundation

//MARK: - Get App Version
/// Retrieves the current app version from the `Info.plist`.
/// - Returns: The app version as a `String`, or "Unknown" if not found.
func getAppVersion() -> String {
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return appVersion
    }
    return "Unknown"
}

/// Retrieves the current app build number from the `Info.plist`.
/// - Returns: The build number as a `String`, or "Unknown" if not found.
func getBuildNumber() -> String {
    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return buildNumber
    }
    return "Unknown"
}

/// Checks if an app update is available by querying the App Store.
/// - Parameter completion: A closure that returns `true` if an update is available, `false` if not, and an optional `Error`.
/// - Throws: `VersionError.invalidBundleInfo` if the app’s bundle info is invalid.
/// - Returns: The `URLSessionDataTask` for the request.
@discardableResult
func isUpdateAvailable(completion: @Sendable @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
    // Retrieve app version and identifier from the bundle's info dictionary
    guard let info = Bundle.main.infoDictionary,
          let currentVersion = info["CFBundleShortVersionString"] as? String,
          let identifier = info["CFBundleIdentifier"] as? String,
          let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
              throw VersionError.invalidBundleInfo // Error if info dictionary is missing critical fields
    }
    
    // Create request with no cache policy to ensure updated data
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
    
    // Start a data task to fetch the latest version from the App Store
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        do {
            // Check for errors in response or if data is nil
            if let error = error { throw error }
            guard let data = data else { throw VersionError.invalidResponse }
            
            // Parse the response JSON to retrieve version information
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
            guard let result = (json?["results"] as? [Any])?.first as? [String: Any],
                  let lastVersion = result["version"] as? String else {
                throw VersionError.invalidResponse // Error if JSON structure is invalid
            }
            
            // Compare current app version with the latest version from the App Store
            print("last version: \(lastVersion) current version: \(currentVersion)")
            completion(lastVersion > currentVersion, nil)
        } catch {
            // If an error occurs, pass it to the completion handler
            completion(nil, error)
        }
    }
    
    // Execute the data task
    task.resume()
    return task
}

/// Custom errors for handling version check issues
enum VersionError: Error {
    case invalidResponse       // Error for when the server response is invalid
    case invalidBundleInfo     // Error for when the app bundle info is missing or malformed
    
    /// Provides a localized description for each error case
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("The server returned an invalid response.", comment: "")
        case .invalidBundleInfo:
            return NSLocalizedString("The bundle info could not be parsed.", comment: "")
        }
    }
}
