//
//  GratitudeListView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/10/24.
//
import SwiftUI
import SwiftData
import Charts
import MijickPopups
import SwipeActions

//MARK: - List View

struct GratitudeListView: View {
    
    //MARK: - Environment
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var path: NavigationPath

    //MARK: - Properties
    
    @State private var selectedDate = Date()
    @State private var noteText: String = ""
    @State private var isShowingHistory = false
    @State private var isScrollAtTop = true
    
    private var calendar = Calendar.current
    private var todayGratitude: DailyGratitude? {
        gratitudes.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    //MARK: - Query & SwiftData
    
    @Query(sort: \DailyGratitude.date, order: .reverse)
    private var gratitudes: [DailyGratitude]
    
    //MARK: - Initializer

    public init(path: Binding<NavigationPath>) {
        _path = path
    }

    //MARK: - Body
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    // Today View
                    if !isShowingHistory {
                        SwipeViewGroup {
                            VStack {
                                headerSection(proxy: proxy)
                                    .padding(.top, 16)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        isShowingHistory = true
                                    }
                                }) {
                                    Label("See History", systemImage: "chevron.down")
                                        .font(.subheadline)
                                        .padding()
                                        .opacity(isScrollAtTop ? 1 : 0) // Show only when at the top
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .contentShape(Rectangle()) // Make the entire view swipeable
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.height < -100 {
                                            withAnimation {
                                                isShowingHistory = true
                                            }
                                        }
                                    }
                            )
                        }
                    }

                    // History View
                    if isShowingHistory {
                        VStack {
                            Button(action: {
                                withAnimation {
                                    isShowingHistory = false
                                }
                            }) {
                                Label("See Today", systemImage: "chevron.up")
                                    .font(.subheadline)
                                    .padding()
                            }
                            SwipeViewGroup {
                                ScrollViewReader { scrollViewProxy in
                                    ScrollView {
                                        Spacer()
                                        if gratitudes.isEmpty {
                                            VStack {
                                                Text("No entries yet.")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                                    .padding()
                                                    .hSpacing(.center)
                                                Button {
                                                    Task {
                                                        await CentrePopup_AddGratitudeEntry(modelContext: modelContext) {
                                                        }
                                                        .present()
                                                    }
                                                } label: {
                                                    Image(systemName: "square.and.pencil")
                                                        .font(.system(size: 60))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        } else {
                                            // Gratitude Streaks (Heatmap)
                                            VStack(alignment: .leading) {
                                                Text("Gratitude Streaks")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                HeatmapView(dailyGratitudes: gratitudes)
                                            }
                                            .padding(.top, 8)
                                            .padding(.horizontal)
                                            
                                            LazyVStack(spacing: 22) {
                                                ForEach(gratitudes) { gratitude in
                                                    SwipeView {
                                                        GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
                                                    } trailingActions: { context in
                                                        SwipeAction(
                                                            systemImage: "trash",
                                                            backgroundColor: .red
                                                        ) {
                                                            HapticManager.shared.trigger(.lightImpact)
                                                            context.state.wrappedValue = .closed
                                                            Task {
                                                                await CentrePopup_DeleteGratitudeEntry(
                                                                    modelContext: modelContext,
                                                                    entry: gratitude,
                                                                    onDelete: { }
                                                                ).present()
                                                            }
                                                        }
                                                        .font(.title.weight(.semibold))
                                                        .foregroundColor(.white)
                                                        
                                                        SwipeAction(
                                                            systemImage: "pencil",
                                                            backgroundColor: Color.teal
                                                        ) {
                                                            HapticManager.shared.trigger(.lightImpact)
                                                            context.state.wrappedValue = .closed
                                                            Task {
                                                                await CentrePopup_AddGratitudeEntry(
                                                                    modelContext: modelContext,
                                                                    entry: gratitude
                                                                ) {
                                                                }
                                                                .present()
                                                            }
                                                        }
                                                        .allowSwipeToTrigger()
                                                        .font(.title.weight(.semibold))
                                                        .foregroundColor(.white)
                                                    }
                                                    .swipeActionCornerRadius(16)
                                                    .swipeSpacing(5)
                                                    .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
                                                    .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
                                                    .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
                                                    .swipeMinimumDistance(25)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .background(GeometryReader {
                                                Color.clear.preference(key: ViewOffsetKey.self,
                                                                       value: -$0.frame(in: .named("scroll")).origin.y)
                                            })
                                            .onPreferenceChange(ViewOffsetKey.self) {
                                                print("offset >> \($0)")
                                                isScrollAtTop = $0 < 10
                                            }
                                        }
                                    }.coordinateSpace(name: "scroll")
                                        
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .contentShape(Rectangle()) // Make the entire view swipeable
                        .simultaneousGesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height > 100 && isScrollAtTop {
                                        withAnimation {
                                            isShowingHistory = false
                                        }
                                    }
                                }
                        )
                    }
                }
            }
            .navigationTitle(isShowingHistory ? "History" : "Today")
        }
    }

    //MARK: - Header Section
    
    @ViewBuilder
    func headerSection(proxy: GeometryProxy) -> some View {
        Section {
            // Today’s Gratitude Entry or Placeholder
            if let gratitude = todayGratitude {
                SwipeView {
                    GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
                } trailingActions: { context in
                    SwipeAction(
                        systemImage: "trash",
                        backgroundColor: .red
                    ) {
                        HapticManager.shared.trigger(.lightImpact)
                        context.state.wrappedValue = .closed
                        Task {
                            await CentrePopup_DeleteGratitudeEntry(
                                modelContext: modelContext,
                                entry: gratitude,
                                onDelete: { }
                            ).present()
                        }
                    }
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                    
                    SwipeAction(
                        systemImage: "pencil",
                        backgroundColor: Color.teal
                    ) {
                        HapticManager.shared.trigger(.lightImpact)
                        context.state.wrappedValue = .closed
                        Task {
                            await CentrePopup_AddGratitudeEntry(
                                modelContext: modelContext,
                                entry: gratitude
                            ) {
                            }
                            .present()
                        }
                    }
                    .allowSwipeToTrigger()
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                }
                .swipeActionCornerRadius(16)
                .swipeSpacing(5)
                .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
                .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
                .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
                .swipeMinimumDistance(25)
            } else {
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
                        await CentrePopup_AddGratitudeEntry(modelContext: modelContext) {
                        }
                        .present()
                    }
                }
            }


            // Milestones & Weekly Progress in a Single Compact Section
            VStack(alignment: .center, spacing: 12) {
                // Milestones
                if gratitudes.count > 0 {
                    Text("🎯 Milestones")
                        .font(.headline)
                        .foregroundColor(.primary)
                    if gratitudes.count % 10 == 0 {
                        HStack {
                            Text("🎉 \(gratitudes.count) entries!")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    Text("Logged \(gratitudes.count) entries so far.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("🏞️ Your gratitude journey begins today!")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                // Weekly Progress
                HStack {
                    ProgressView(value: Double(gratitudes.count), total: 7.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 80)

                    Text("\(gratitudes.count)/7 entries this week")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)


            // Reflection Summary
            VStack(alignment: .center) {
                if let firstEntry = gratitudes.last {
                    Text("📝 Reflection Summary")
                        .font(.headline)
                        .foregroundColor(.primary)
                        
                    Text("You started your gratitude journey on \n\(firstEntry.date, style: .date).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.center)
                    if let mostRecent = gratitudes.first {
                        Text("Your last entry was \(mostRecent.date, style: .relative).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("🎬 Start your gratitude journey today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)

           

            // Memory of Gratitude
            if let randomGratitude = gratitudes.randomElement() {
                VStack(alignment: .center) {
                    Text("🧠 Memory of Gratitude")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("On \(randomGratitude.date, style: .date), you wrote:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(randomGratitude.entry1)")
                        .font(.body)
                }
                .transition(.identity) // Explicitly set no transition
            }

                Text("“Gratitude turns what we have into enough.”")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .hSpacing(.center)
                    .vSpacing(.bottom)
        }
        .padding(.horizontal, 16)
    }
}

//MARK: - Add Popup

struct CentrePopup_AddGratitudeEntry: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var onDone: () -> Void
    
    @State private var entry1: String
    @State private var entry2: String
    @State private var entry3: String
    @State private var notes: String
    @State private var error: String?

    private var existingEntry: DailyGratitude?

    init(modelContext: ModelContext, entry: DailyGratitude? = nil, onDone: @escaping () -> Void) {
        self.modelContext = modelContext
        self.existingEntry = entry
        self.onDone = onDone
        
        // Prepopulate fields if editing, otherwise leave them empty
        _entry1 = State(initialValue: entry?.entry1 ?? "")
        _entry2 = State(initialValue: entry?.entry2 ?? "")
        _entry3 = State(initialValue: entry?.entry3 ?? "")
        _notes = State(initialValue: entry?.notes ?? "")
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Dynamic Title
            Text(existingEntry == nil ? "Add Gratitude Entry" : "Edit Gratitude Entry")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Entry TextFields
            VStack(alignment: .leading, spacing: 12) {
                Text("Entries")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("🌟")
                        .font(.title2)
                    createStyledTextField("Gratitude Entry 1", text: $entry1)
                }
                
                HStack {
                    Text("❤️")
                        .font(.title2)
                    createStyledTextField("Gratitude Entry 2", text: $entry2)
                }
                
                HStack {
                    Text("🍃")
                        .font(.title2)
                    createStyledTextField("Gratitude Entry 3", text: $entry3)
                }
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
                Button(action: {
                    Task { await dismissLastPopup() }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red.opacity(0.1)) // Subtle red tint
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)

                Button(action: {
                    Task {
                        let result = await saveGratitudeEntry()
                        if result.isSuccess {
                            await dismissLastPopup()
                            onDone()
                        } else {
                            error = "Error saving entry. Please try again."
                        }
                    }
                }) {
                    Text(existingEntry == nil ? "Save" : "Update")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
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
    
    
    func saveGratitudeEntry() async -> Result<Void, Error> {
        guard !entry1.isEmpty && !entry2.isEmpty && !entry3.isEmpty else {
            print("Cannot save: One or more entries are empty")
            return .failure(ValidationError.emptyEntries)
        }
        
        do {
            if let existingEntry = existingEntry {
                // Update the existing entry
                existingEntry.entry1 = entry1
                existingEntry.entry2 = entry2
                existingEntry.entry3 = entry3
                existingEntry.notes = notes
            } else {
                // Create a new entry
                let newEntry = DailyGratitude(entry1: entry1, entry2: entry2, entry3: entry3, notes: notes)
                modelContext.insert(newEntry)
            }
            
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    enum ValidationError: Error {
        case emptyEntries
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

//MARK: - Delete Popup

struct CentrePopup_DeleteGratitudeEntry: CenterPopup {
    @State var modelContext: ModelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var entry: DailyGratitude
    var onDelete: () -> Void
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            // Title
            Text("Delete Gratitude Entry")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Warning Message
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            
            // Display entry content for reference
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🌟")
                        .font(.title2)
                    Text(entry.entry1)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("❤️")
                        .font(.title2)
                    Text(entry.entry2)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("🍃")
                        .font(.title2)
                    Text(entry.entry3)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                if !entry.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(entry.notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    Task { await dismissLastPopup() }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)

                Button(action: {
                    deleteGratitudeEntry()
                    Task { await dismissLastPopup() }
                    
                    onDelete()
                }) {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
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
    }
    
    func deleteGratitudeEntry() {
        modelContext.delete(entry)
        do {
            try modelContext.save()
            print("Gratitude entry deleted successfully.")
        } catch {
            print("Error deleting gratitude entry: \(error)")
        }
    }
}

//MARK: Heatmap

struct HeatmapView: View {
    var dailyGratitudes: [DailyGratitude]

    var body: some View {
        Chart {
            ForEach(dailyGratitudes, id: \.id) { gratitude in
                RectangleMark(
                    x: .value("Date", gratitude.date, unit: .day),
                    y: .value("Streak", 1) // Keep y constant for a grid-like look
                )
                .foregroundStyle(by: .value("Streak", gratitude.streak))
            }
        }
        .chartForegroundStyleScale(range: [.gray, .blue]) // Adjust colors for streak levels
        .frame(height: 100) // Compact heatmap
        .padding()
    }
}


//MARK: - Previews

#Preview {
    @Previewable @State var path = NavigationPath()
    GratitudeListView(path: $path)
        .modelContainer(DailyGratitude.preview)
}

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

#Preview {
   
    CentrePopup_AddGratitudeEntry(
        modelContext: DailyGratitude.preview.mainContext
    ) {
        
    }
}
