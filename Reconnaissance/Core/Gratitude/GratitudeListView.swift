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
    
    private var thisWeeksGratitudes: [DailyGratitude] {
        gratitudes.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    
    @State private var selectedDateRange: DateRange = .today
    @State private var customDateRange: ClosedRange<Date> = Date()...Date()
    @State private var showDatePicker = false
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var showCustomDatePicker = false
    @State private var selectedSortOption: SortOption = .dateDescending
    @State private var currentCardIndex = 0
    
    @State var randomGratitude: DailyGratitude?
    
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
                                        HapticManager.shared.trigger(.lightImpact)
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
                                                HapticManager.shared.trigger(.lightImpact)
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
                                    HapticManager.shared.trigger(.lightImpact)
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
                                                        HapticManager.shared.trigger(.lightImpact)
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
                                                    availableWidth: proxy.size.width
                                                )
                                            }
                                            .padding(.top, 8)
                                            .padding(.horizontal)
                                            
                                            
                                            LazyVStack(spacing: 22) {
                                                ScrollViewReader { proxy in
                                                    ScrollView(.horizontal, showsIndicators: false) {
                                                        HStack(spacing: 10) {
                                                            chipView(title: "Today", isSelected: selectedDateRange == .today) {
                                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                                    selectedDateRange = .today
                                                                    proxy.scrollTo("Today", anchor: .center)
                                                                }
                                                            }
                                                            .id("Today")
                                                            
                                                            chipView(title: "Yesterday", isSelected: selectedDateRange == .yesterday) {
                                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                                    selectedDateRange = .yesterday
                                                                    proxy.scrollTo("Yesterday", anchor: .center)
                                                                }
                                                            }
                                                            .id("Yesterday")
                                                            
                                                            chipView(title: "This Week", isSelected: selectedDateRange == .thisWeek) {
                                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                                    selectedDateRange = .thisWeek
                                                                    proxy.scrollTo("This Week", anchor: .center)
                                                                }
                                                            }
                                                            .id("This Week")
                                                            
                                                            chipView(title: "Last Week", isSelected: selectedDateRange == .lastWeek) {
                                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                                    selectedDateRange = .lastWeek
                                                                    proxy.scrollTo("Last Week", anchor: .center)
                                                                }
                                                            }
                                                            .id("Last Week")
                                                            
                                                            chipView(title: "Custom Range", isSelected: selectedDateRange == .custom) {
                                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                                    selectedDateRange = .custom
                                                                    Task {
                                                                        let calendar = Calendar.current
                                                                        let todayStartOfDay = calendar.startOfDay(for: Date())
                                                                        let todayEndOfDay = calendar.date(byAdding: .day, value: 1, to: todayStartOfDay)!.addingTimeInterval(-1)
                                                                        
                                                                        customDateRange = todayStartOfDay...todayEndOfDay
                                                                        
                                                                        await CalendarPopup(startDate: $startDate, endDate: $endDate) {
                                                                            let startOfDay = calendar.startOfDay(for: startDate ?? Date())
                                                                            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate ?? Date()))!.addingTimeInterval(-1)
                                                                            
                                                                            customDateRange = startOfDay...endOfDay
                                                                        }
                                                                        .present()
                                                                    }
                                                                    proxy.scrollTo("Custom Range", anchor: .center)
                                                                }
                                                            }
                                                            .id("Custom Range")
                                                        }
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                    }
                                                    // Add this `.onChange` modifier to automatically scroll to the selected chip
                                                    .onChange(of: selectedDateRange) { newValue, _ in
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            switch newValue {
                                                            case .today:
                                                                HapticManager.shared.trigger(.lightImpact)
                                                                proxy.scrollTo("Today", anchor: .center)
                                                            case .yesterday:
                                                                HapticManager.shared.trigger(.lightImpact)
                                                                proxy.scrollTo("Yesterday", anchor: .center)
                                                            case .thisWeek:
                                                                HapticManager.shared.trigger(.lightImpact)
                                                                proxy.scrollTo("This Week", anchor: .center)
                                                            case .lastWeek:
                                                                HapticManager.shared.trigger(.lightImpact)
                                                                proxy.scrollTo("Last Week", anchor: .center)
                                                            case .custom:
                                                                HapticManager.shared.trigger(.lightImpact)
                                                                proxy.scrollTo("Custom Range", anchor: .center)
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                if filteredGratitudes.isEmpty {
                                                    Text("No entries.")
                                                        .font(.headline)
                                                        .foregroundColor(.secondary)
                                                        .padding()
                                                        .hSpacing(.center)
                                                } else {
                                                    ForEach(filteredGratitudes) { gratitude in
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
                                                        value: filteredGratitudes
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
                                            HapticManager.shared.trigger(.lightImpact)
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
                        .onChange(of: selectedDateRange) { newRange , _ in
                            if selectedDateRange == .custom {
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
                            //proxy.scrollTo(newRange.rawValue, anchor: .center)
                        }
                    }
                }
            }
            .navigationTitle(viewState.isShowingHistory ? "History" : "Today")
            .onAppear {
                randomGratitude = gratitudes.randomElement()
            }
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
                        HapticManager.shared.trigger(.lightImpact)
                        await CentrePopup_AddGratitudeEntry(modelContext: modelContext) {
                            ConfettiController.showConfettiOverlay()
                        }
                        .present()
                    }
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Milestones & Weekly Progress
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 Milestones")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if gratitudes.count > 0 {
                            Text("🎉 \(gratitudes.count) entries!")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Logged \(gratitudes.count) entries so far.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        CircularProgressView(
                            progress: Double(thisWeeksGratitudes.count) / 7.0,
                            color: .blue,
                            lineWidth: 5
                        )
                        .frame(width: 50, height: 50)
                        
                        VStack(spacing: 2) {
                            Text("\(thisWeeksGratitudes.count)/7")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Week Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Conditional Rendering Based on Screen Size
                if UIScreen.main.bounds.width <= 375 {
                    // iPhone SE-like Devices: Swipeable ZStack Carousel
                    ZStack {
                        // Reflection Card with Right Arrow
                        HStack(spacing: 0) {
                            reflectionCard
                                .offset(x: currentCardIndex == 0 ? 0 : -UIScreen.main.bounds.width) // Move card off-screen
                                .animation(.spring(), value: currentCardIndex)
                                .zIndex(currentCardIndex == 0 ? 1 : 0)
                            // Right Arrow (only visible when `currentCardIndex == 1`)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .opacity(currentCardIndex == 0 ? 1 : 0) // Visible when the first card is shown
                                .animation(.easeInOut, value: currentCardIndex) // Smoothly fade in/out
                        }
                        
                        // Memory Card with Left Arrow
                        HStack(spacing: 0) {
                            // Left Arrow (only visible when `currentCardIndex == 0`)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .opacity(currentCardIndex == 1 ? 1 : 0) // Visible when the second card is shown
                                .animation(.easeInOut, value: currentCardIndex) // Smoothly fade in/out
                            memoryCard
                                .offset(x: currentCardIndex == 1 ? 0 : UIScreen.main.bounds.width) // Move card off-screen
                                .animation(.spring(), value: currentCardIndex)
                                .zIndex(currentCardIndex == 1 ? 1 : 0)
                            
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    currentCardIndex = min(currentCardIndex + 1, 1)
                                } else if value.translation.width > 0 {
                                    currentCardIndex = max(currentCardIndex - 1, 0)
                                }
                            }
                    )
                } else {
                    // Other Devices: Standard VStack
                    VStack(alignment: .leading, spacing: 12) {
                        reflectionCard
                        memoryCard
                    }
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
    
    // Reflection Card View
        private var reflectionCard: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("📝 Reflection Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let firstEntry = gratitudes.last {
                    Text("Started: \(firstEntry.date, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let mostRecent = gratitudes.first {
                        Text("Last entry: \(mostRecent.date, style: .relative)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Start your gratitude journey today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        
        // Memory Card View
        private var memoryCard: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("🧠 Memory of Gratitude")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let randomGratitude = randomGratitude {
                    Text("On \(randomGratitude.date, style: .date), you wrote:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\"\(randomGratitude.entry1)\"")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text("No memories yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
    
    @FocusState private var focusedField: Field?
        
    enum Field {
        case field1, field2, field3, field4
    }
    
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
                    createStyledTextField(
                        "Gratitude Entry 1",
                        text: $entry1,
                        field: .field1
                    )
                }
                
                HStack {
                    Text("❤️")
                        .font(.title2)
                    createStyledTextField("Gratitude Entry 2", text: $entry2, field: .field2)
                }
                
                HStack {
                    Text("🍃")
                        .font(.title2)
                    createStyledTextField("Gratitude Entry 3", text: $entry3, field: .field3)
                }
            }
            
            // Notes Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                createStyledTextField("Notes. Write something here...", text: $notes, isMultiline: true, field: .field4)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
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
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        let result = await saveGratitudeEntry()
                        if result.isSuccess {
                            HapticManager.shared.trigger(.success)
                            await dismissLastPopup()
                            onDone()
                        } else {
                            HapticManager.shared.trigger(.error)
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
    
    @FocusState private var isFocused: Bool

    func createStyledTextField(_ placeholder: String, text: Binding<String>, isMultiline: Bool = false, field: Field) -> some View {
        Group {
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: field) // Use appropriate field enum
            } else {
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field) // Use appropriate field enum
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(text.wrappedValue.isEmpty ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
        .onTapGesture {
            focusedField = field // Use appropriate field enum
        }
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
        config
            //.popupHorizontalPadding(24)
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
                    HapticManager.shared.trigger(.lightImpact)
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
                    HapticManager.shared.trigger(.lightImpact)
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
            HapticManager.shared.trigger(.success)
            print("Gratitude entry deleted successfully.")
        } catch {
            HapticManager.shared.trigger(.error)
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
