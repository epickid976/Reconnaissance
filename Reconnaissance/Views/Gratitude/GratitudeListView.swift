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
    
    // MARK: - ViewState
    @StateObject private var viewState = GratitudeViewState.shared // Use the shared state
    
    //MARK: - Properties
    
    @State private var selectedDate = Date()
    @State private var noteText: String = ""
    @State private var isScrollAtTop = true
    
    private var calendar = Calendar.current
    private var todayGratitude: DailyGratitude? {
        gratitudes.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    @State private var selectedDateRange: DateRange = .today
    @State private var customDateRange: ClosedRange<Date> = Date()...Date()
    @State private var showDatePicker = false
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var showCustomDatePicker = false
    @State private var selectedSortOption: SortOption = .dateDescending
    
    var filteredGratitudes: [DailyGratitude] {
        switch selectedDateRange {
        case .today:
            return gratitudes.filter { calendar.isDateInToday($0.date) }
        case .yesterday:
            return gratitudes.filter { calendar.isDateInYesterday($0.date) }
        case .thisWeek:
            return gratitudes.filter {
                calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
            }
        case .lastWeek:
            return gratitudes.filter {
                let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())
                return calendar.isDate($0.date, equalTo: lastWeek ?? Date(), toGranularity: .weekOfYear)
            }
        case .custom:
            return gratitudes.filter { customDateRange.contains($0.date) }
        }
    }
    
    var sortedFilteredGratitudes: [DailyGratitude] {
        let filtered = filteredGratitudes
        switch selectedSortOption {
        case .dateAscending:
            return filtered.sorted(by: { $0.date < $1.date })
        case .dateDescending:
            return filtered.sorted(by: { $0.date > $1.date })
        case .alphabetical:
            return filtered.sorted(by: { $0.entry1.localizedCompare($1.entry1) == .orderedAscending })
        }
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
                    if !viewState.isShowingHistory {
                        SwipeViewGroup {
                            VStack {
                                headerSection(proxy: proxy)
                                    .padding(.top, 16)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        viewState.isShowingHistory = true
                                    }
                                }) {
                                    Label("See History", systemImage: "chevron.down")
                                        .font(.subheadline)
                                        .bold()
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
                                                viewState.isShowingHistory = true
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    
                    // History View
                    if viewState.isShowingHistory {
                        VStack {
                            Button(action: {
                                withAnimation {
                                    viewState.isShowingHistory = false
                                }
                            }) {
                                Label("See Today", systemImage: "chevron.up")
                                    .font(.subheadline)
                                    .bold()
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
                                                HeatmapView(
                                                    dailyGratitudes: gratitudes,
                                                    availableWidth: proxy.size.width)
                                            }
                                            .padding(.top, 8)
                                            .padding(.horizontal)
                                            
                                            
                                            LazyVStack(spacing: 22) {
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 10) {
                                                        chipView(title: "Today", isSelected: selectedDateRange == .today) {
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                selectedDateRange = .today
                                                            }
                                                        }
                                                        chipView(title: "Yesterday", isSelected: selectedDateRange == .yesterday) {
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                selectedDateRange = .yesterday
                                                            }
                                                        }
                                                        chipView(title: "This Week", isSelected: selectedDateRange == .thisWeek) {
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                selectedDateRange = .thisWeek
                                                            }
                                                        }
                                                        chipView(title: "Last Week", isSelected: selectedDateRange == .lastWeek) {
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                selectedDateRange = .lastWeek
                                                            }
                                                        }
                                                        chipView(title: "Custom Range", isSelected: selectedDateRange == .custom) {
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                selectedDateRange = .custom
                                                                Task {
                                                                    // Use a default value in case `onDone` isn't triggered
                                                                    let calendar = Calendar.current
                                                                    let todayStartOfDay = calendar.startOfDay(for: Date())
                                                                    let todayEndOfDay = calendar.date(byAdding: .day, value: 1, to: todayStartOfDay)!.addingTimeInterval(-1)
                                                                    
                                                                    customDateRange = todayStartOfDay...todayEndOfDay
                                                                    
                                                                    await CalendarPopup(startDate: $startDate, endDate: $endDate) {
                                                                        // Ensure `customDateRange` is updated only if `onDone` is called
                                                                        let startOfDay = calendar.startOfDay(for: startDate ?? Date())
                                                                        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate ?? Date()))!.addingTimeInterval(-1)
                                                                        
                                                                        customDateRange = startOfDay...endOfDay
                                                                    }
                                                                    .present()
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.horizontal, 16) // Add sufficient padding here
                                                    .padding(.vertical, 8)   // Optional vertical padding for spacing
                                                }
                                                
                                                
                                                if sortedFilteredGratitudes.isEmpty {
                                                    Text("No entries.")
                                                        .font(.headline)
                                                        .foregroundColor(.secondary)
                                                        .padding()
                                                        .hSpacing(.center)
                                                } else {
                                                    ForEach(sortedFilteredGratitudes) { gratitude in
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
                                                    .animation(
                                                        .spring(),
                                                        value: sortedFilteredGratitudes
                                                    )
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
                                        Spacer()
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
                                            viewState.isShowingHistory = false
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    handleDateRangeSwipe(value.translation.width)
                                }
                        )
                    }
                }
            }
            .navigationTitle(viewState.isShowingHistory ? "History" : "Today")
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
            .padding(.vertical, 8)
            
            
            
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
                .padding(.vertical, 8)
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
    
    private func handleDateRangeSwipe(_ translation: CGFloat) {
        let dateRangeOptions: [DateRange] = [.today, .yesterday, .thisWeek, .lastWeek, .custom]
        
        guard let currentIndex = dateRangeOptions.firstIndex(of: selectedDateRange) else {
            return
        }
        
        var newIndex = currentIndex
        
        if translation < -50 {
            // Swipe left - move to next filter
            newIndex = min(currentIndex + 1, dateRangeOptions.count - 1)
        } else if translation > 50 {
            // Swipe right - move to previous filter
            newIndex = max(currentIndex - 1, 0)
        }
        
        if newIndex != currentIndex {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDateRange = dateRangeOptions[newIndex]
            }
        }
    }
}

//MARK: - Chip View

@ViewBuilder
func chipView(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
    Text(title)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .animation(.easeInOut(duration: 0.3), value: isSelected) // Smooth color transition
        )
        .foregroundColor(isSelected ? .white : .primary)
        .font(.system(size: isSelected ? 16 : 14, weight: .bold)) // Animate font size
        .scaleEffect(isSelected ? 1.1 : 1.0) // Scale effect for selected chip
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3), value: isSelected) // Spring animation
        .onTapGesture {
            withAnimation {
                action()
            }
        }
}

//MARK: - Sorting Chip View

@ViewBuilder
func sortingChipView(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
    Text(title)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .animation(.easeInOut(duration: 0.3), value: isSelected)
        )
        .foregroundColor(isSelected ? .white : .primary)
        .fontWeight(isSelected ? .bold : .regular)
        .clipShape(Capsule())
        .onTapGesture {
            withAnimation {
                action()
            }
        }
}

//MARK: - Calendar Popup

struct CalendarPopup: CenterPopup {
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    var onDone: () -> Void
    
    var body: some View {
        VStack {
            CustomDateRangePicker(startDate: $startDate, endDate: $endDate) {
                onDone()
                Task { await dismissLastPopup()}
            }
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .tapOutsideToDismissPopup(true)
        
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
                DailyGratitude.calculateAndUpdateStreak(
                    for: newEntry,
                    in: modelContext
                )
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

//MARK: - Enums for Sort & Filter

enum DateRange {
    case today, yesterday, thisWeek, lastWeek, custom
}
enum SortOption: String, CaseIterable {
    case dateAscending = "Date (Oldest First)"
    case dateDescending = "Date (Newest First)"
    case alphabetical = "Alphabetical"
}

final class GratitudeViewState: ObservableObject {
    static let shared = GratitudeViewState()

    @Published var isShowingHistory: Bool = false
}


//MARK: - Previews

#Preview("List") {
    @Previewable @State var path = NavigationPath()
    GratitudeListView(path: $path)
        .modelContainer(DailyGratitude.preview)
}

#Preview("Cell") {
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

#Preview("Add Popup") {
    
    CentrePopup_AddGratitudeEntry(
        modelContext: DailyGratitude.preview.mainContext
    ) {
        
    }
}

#Preview("Calendar") {
    @Previewable @State var startDate: Date? = nil
    @Previewable @State var endDate: Date? = nil
    
    CalendarPopup(startDate: $startDate, endDate: $endDate) {
        
    }
}
