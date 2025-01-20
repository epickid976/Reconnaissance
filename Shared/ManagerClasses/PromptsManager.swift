//
//  PromptsManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 1/20/25.
//

import SwiftUI
@MainActor
final class PromptsManager {
    static let shared = PromptsManager()

    private let promptsKey = "promptsKey"
    private let defaults = UserDefaults.standard

    private init() {
        // Seed default prompts if none exist
        if defaults.array(forKey: promptsKey) as? [String] == nil {
            defaults.set(defaultPrompts, forKey: promptsKey)
        }
    }

    var prompts: [String] {
        get {
            defaults.array(forKey: promptsKey) as? [String] ?? []
        }
        set {
            defaults.set(newValue, forKey: promptsKey)
        }
    }

    private let defaultPrompts: [String] = [
        "What made you smile today?",
        "What are you grateful for today?",
        "What made today special?",
        "What made today awesome?",
        "What made today amazing?",
        "What made today great?",
        "What made today wonderful?",
        "What made today fantastic?",
        "What made today incredible?",
        "What made today extraordinary?",
        "What made today memorable?",
        "What made today magical?",
        "What made today marvelous?",
        "What made today splendid?",
        "What made today terrific?",
        "What made today delightful?",
        "What made today fabulous?",
        "What made today superb?",
        "What made today exceptional?",
        "What made today phenomenal?",
        "What made today unforgettable?",
        "What made today remarkable?",
        "What made today outstanding?",
        "What made today magnificent?",
        "What made today brilliant?",
        "What made today glorious?",
        "What made today grand?",
        "What made today majestic?",
        "What made today sublime?",
        "What made today divine?",
        "What made today heavenly?",
        "What made today blissful?",
        "What made today serene?",
        "What made today tranquil?",
        "What made today peaceful?",
        "What made today calm?",
        "What made today quiet?",
        "What made today still?",
        "What made today restful?",
        "What made today relaxing?",
        "What made today soothing?",
        "What made today refreshing?",
        "What made today invigorating?",
        "What made today energizing?",
        "What made today inspiring?",
        "What made today motivating?",
        "What made today encouraging?",
        "What made today uplifting?",
        "What made today heartwarming?",
        "What made today touching?",
        "What made today moving?",
        "What made today emotional?",
        "What made today sentimental?",
        "What made today nostalgic?",
        "What made today heartening?",
        "What made today warming?",
        "What made today comforting?",
        "What made today reassuring?",
        "What made today consoling?",
        "What made today supportive?",
        "What made today encouraging?",
        "What made today inspiring?",
        "What made today motivating?",
        "What made today uplifting?",
        "What made today heartwarming?",
        "What made today touching?",
        "What made today moving?",
        "What made today emotional?",
        "What made today sentimental?"
    ]
}
