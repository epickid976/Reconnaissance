//
//  SpacesEntry.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//

import SwiftData
import SwiftUI

@Model
class SpaceCategory {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "folder"
    var color: CategoryColor = CategoryColor.blue // Store color as an enum
    
    init(name: String, icon: String, color: CategoryColor) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
    }
}

enum CategoryColor: String, CaseIterable, Codable {
    case red, blue, green, yellow, purple, gray
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .purple: return .purple
        case .gray: return .gray
        }
    }
    
    // Initialize from a Color
    init?(from color: Color) {
        switch color {
        case .red: self = .red
        case .blue: self = .blue
        case .green: self = .green
        case .yellow: self = .yellow
        case .purple: self = .purple
        case .gray: self = .gray
        default: return nil // For unsupported colors
        }
    }
}

enum ItemType: String, Codable {
    case document
    case image
    case text
}

@Model
class Item {
    var id: UUID = UUID()
    var name: String = ""
    var type: ItemType = ItemType.text
    var categoryID: UUID = UUID()
    var dataURL: URL? // URL to the document, image, or other resource
    var text: String? // Text content for `text` type
    
    init(name: String, type: ItemType, categoryID: UUID, dataURL: URL? = nil, text: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.categoryID = categoryID
        self.dataURL = dataURL
        self.text = text
    }
}

