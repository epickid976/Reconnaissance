//
//  ResultExtensions.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/27/24.
//


// ResultExtensions.swift
// Provides convenient extensions for Swift's Result type inspired by Kotlin's functional programming approach.

import Foundation

extension Result {
    
    // MARK: - isSuccess and isFailure Properties
    
    /// Returns `true` if the result is a success, otherwise `false`.
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    /// Returns `true` if the result is a failure, otherwise `false`.
    var isFailure: Bool {
        return !isSuccess
    }
    
    // MARK: - getOrNil
    
    /// Returns the success value if the result is a success, or `nil` if it's a failure.
    /// Useful when you don't need to handle the error and want an optional result.
    func getOrNil() -> Success? {
        return try? get()
    }
    
    // MARK: - getOrElse
    
    /// Returns the success value if the result is a success, or a provided default value if it's a failure.
    /// - Parameter defaultValue: The value to return if the result is a failure.
    func getOrElse(_ defaultValue: Success) -> Success {
        return (try? get()) ?? defaultValue
    }
    
    // MARK: - fold
    
    /// Transforms the success or failure of the result into a single value.
    /// - Parameters:
    ///   - onSuccess: A closure that transforms the success value.
    ///   - onFailure: A closure that transforms the failure error.
    /// - Returns: The result of `onSuccess` if the result is a success, otherwise the result of `onFailure`.
    func fold<T>(onSuccess: (Success) -> T, onFailure: (Failure) -> T) -> T {
        switch self {
        case .success(let value): return onSuccess(value)
        case .failure(let error): return onFailure(error)
        }
    }
    
    // MARK: - mapError
    
    /// Maps a failure to a new error while leaving the success value unchanged.
    /// - Parameter transform: A closure that transforms the error.
    /// - Returns: A `Result` with the transformed error if the result is a failure.
    func mapError<NewFailure: Error>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value): return .success(value)
        case .failure(let error): return .failure(transform(error))
        }
    }
    
    // MARK: - runCatching Function
    
    /// Wraps a throwing function in a Result, catching any thrown errors.
    /// Allows you to handle `throws` functions without `do-catch`.
    /// - Parameter operation: A closure that may throw an error.
    /// - Returns: A Result containing the success value or failure error.
    static func runCatching<T>(_ operation: () throws -> T) -> Result<T, Error> {
        do {
            return .success(try operation())
        } catch {
            return .failure(error)
        }
    }
}

extension Result where Success == Bool {
    func onSuccess(_ action: () -> Void) -> Result {
        if case .success(true) = self {
            action()
        }
        return self
    }
}
