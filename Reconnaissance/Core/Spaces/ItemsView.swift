//
//  ItemsView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//
import SwiftUI
import SwiftData

struct ItemsView: View {
    let category: SpaceCategory
    @Query private var items: [Item]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items.filter { $0.categoryID == category.id }) { item in
                    ItemCell(item: item)
                }
            }
            .navigationTitle(category.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addItem) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func addItem() {
        // Logic to add a new item
    }
}

struct ItemCell: View {
    let item: Item
    
    var body: some View {
        HStack {
            icon(for: item.type)
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(typeDescription(for: item.type))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func icon(for type: ItemType) -> Image {
        switch type {
        case .document: return Image(systemName: "doc.text")
        case .image: return Image(systemName: "photo")
        case .text: return Image(systemName: "text.bubble")
        }
    }
    
    private func typeDescription(for type: ItemType) -> String {
        switch type {
        case .document: return "Document"
        case .image: return "Image"
        case .text: return "Text"
        }
    }
}
