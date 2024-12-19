//
//  Actors.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/18/24.
//

// MARK: - Global Actors
@globalActor actor SyncActor: GlobalActor {
    static var shared = SyncActor()
}

@globalActor actor BackgroundActor: GlobalActor {
    static var shared = BackgroundActor()
}

extension BackgroundActor {
    // Custom run function
    static func run<T>(_ operation: @escaping () async -> T) async -> T {
        await operation()
    }
}
