//
//  ContentView.swift
//  Reconnaissance Watch Watch App
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var gratitudes: [DailyGratitude]
    
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .onTapGesture {
                    modelContext.insert(DailyGratitude(entry1: "entry1", entry2: "entry2", entry3: "entry3"))
                }
            Text("Hello, world!")
            List {
                ForEach(gratitudes) { gratitude in
                    Text(gratitude.entry1)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
