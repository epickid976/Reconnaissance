//
//  GratitudeListView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/10/24.
//
import SwiftUI
import SwiftData
import MijickPopups

//MARK: - List View

struct GratitudeListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var path: NavigationPath

    @State private var selectedDate = Date()
    @State private var noteText: String = ""
    @State private var isEditingEntry = false // Controls sheet presentation

    @Query(sort: \DailyGratitude.date, order: .reverse)
    private var gratitudes: [DailyGratitude]

    private var calendar = Calendar.current
    private var todayGratitude: DailyGratitude? {
        gratitudes.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    public init(path: Binding<NavigationPath>) {
        _path = path
    }

    var body: some View {
            NavigationStack {
                GeometryReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 22) {
                        // Section for Today's Gratitude
                        Section {
                            if let gratitude = todayGratitude {
                                GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
                                    .onTapGesture {
                                        selectedDate = gratitude.date
                                        noteText = gratitude.notes
                                        isEditingEntry = true
                                    }
                            } else {
                                // Placeholder Cell
                                VStack {
                                    HStack {
                                        Text("No entry for today")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    HStack {
                                        Text("Tap to add something you're grateful for.")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                                )
                                .onTapGesture {
                                    Task {
                                        await CentrePopup_AddGratitudeEntry {
                                            
                                        }.present()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Past Gratitude Entries
                        ForEach(gratitudes) { gratitude in
                            GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
                                .onTapGesture {
                                    selectedDate = gratitude.date
                                    noteText = gratitude.notes
                                    isEditingEntry = true
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .navigationTitle("Gratitude Journal")
                    .navigationBarTitleDisplayMode(.large)
                    .sheet(isPresented: $isEditingEntry) {
                        GratitudeEditorView(date: selectedDate, noteText: $noteText) { savedNote in
                            saveNoteForDate(selectedDate, note: savedNote)
                            isEditingEntry = false
                        }
                    }
                }
            }
        }
    }

    private func saveNoteForDate(_ date: Date, note: String) {
        // Save or update the gratitude entry for the selected date
        var newEntry: DailyGratitude
        
        if let entry = gratitudes.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            entry.notes = note
            newEntry = entry
        } else {
            let newEntry1 = DailyGratitude(entry1: "", entry2: "", entry3: "", notes: note)
            newEntry = newEntry1
        }

        modelContext.insert(newEntry)
    }
}

struct GratitudeEditorView: View {
    let date: Date
    @Binding var noteText: String
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Entry for \(formattedDate(date))")
                    .font(.headline)

                TextField("What are you grateful for?", text: $noteText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()

                Button("Save") {
                    onSave(noteText)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Edit Gratitude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave(noteText) // Optionally pass the unsaved note
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CentrePopup_AddGratitudeEntry: CenterPopup {
    @Environment(\.modelContext) var modelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var onDone: () -> Void
    
    @State private var entry1: String = ""
    @State private var entry2: String = ""
    @State private var entry3: String = ""
    @State private var notes: String = ""
    
    init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Title
            Text("🌟 Add Gratitude Entry")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Entry TextFields
            VStack(alignment: .leading, spacing: 12) {
                Text("Entries")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                createStyledTextField("🌟 Gratitude Entry 1", text: $entry1)
                createStyledTextField("❤️ Gratitude Entry 2", text: $entry2)
                createStyledTextField("🍃 Gratitude Entry 3", text: $entry3)
            }
            
            // Notes Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                createStyledTextField("Notes. Write something here...", text: $notes, isMultiline: true)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    Task { await dismissLastPopup() }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.1)) // Subtle red tint
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.8), lineWidth: 1)
                )
                .foregroundColor(.red)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)

                Button("Save") {
                    saveGratitudeEntry()
                    Task { await dismissLastPopup() }
                    onDone()
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                )
                .foregroundColor(.blue)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hideKeyboardOnDrag()
    }

    // Helper for Styled Text Fields
    func createStyledTextField(_ placeholder: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        Group {
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(3...6)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1)) // Subtle tint for visibility
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(text.wrappedValue.isEmpty ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        .foregroundColor(colorScheme == .dark ? Color.white : Color.black) // Ensure text color adapts
    }
    
    func saveGratitudeEntry() {
        let newEntry = DailyGratitude(entry1: entry1, entry2: entry2, entry3: entry3, notes: notes)
        modelContext.insert(newEntry)
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}


//MARK: - Preview

#Preview {
    ScrollView {
        LazyVStack(spacing: 20) { // Add spacing to separate cells
            GratitudeCell(
                gratitude: DailyGratitude.exampleYesterday,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
        }
        .padding()
    }
}
