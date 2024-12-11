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

//MARK: - List View

struct GratitudeListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var path: NavigationPath

    @State private var selectedDate = Date()
    @State private var noteText: String = ""
    @State private var isShowingHistory = false
    @State private var isScrollAtTop = true
    
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
                ZStack {
                    // Today View
                    if !isShowingHistory {
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

                            ScrollViewReader { scrollViewProxy in
                                ScrollView {
                                    Spacer()
                                    
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
                                            GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
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
                                    
                                }.coordinateSpace(name: "scroll")
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

    @ViewBuilder
    func headerSection(proxy: GeometryProxy) -> some View {
        Section {
            // Today’s Gratitude Entry or Placeholder
            if let gratitude = todayGratitude {
                GratitudeCell(gratitude: gratitude, mainWindowSize: proxy.size)
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
                        await CentrePopup_AddGratitudeEntry {
                        }
                        .present()
                    }
                }
            }


            // Milestones & Weekly Progress in a Single Compact Section
            VStack(alignment: .center, spacing: 12) {
                // Milestones
                if gratitudes.count > 0 {
                    Text("Milestones")
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
                    Text("Your gratitude journey begins today!")
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
                    Text("Reflection Summary")
                        .font(.headline)
                        .foregroundColor(.primary)
                        
                    Text("You started your gratitude journey on \(firstEntry.date, style: .date).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if let mostRecent = gratitudes.first {
                        Text("Your last entry was \(mostRecent.date, style: .relative).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Start your gratitude journey today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)

           

            // Memory of Gratitude
            if let randomGratitude = gratitudes.randomElement() {
                VStack(alignment: .center) {
                    Text("Memory of Gratitude")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("On \(randomGratitude.date, style: .date), you wrote:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Text("“\(randomGratitude.entry1)”")
                        .font(.body) // Regular font instead of italic
                        .padding(.top, 4)
                }
            }

            // Quote of the Day
            HStack {
                Text("“Gratitude turns what we have into enough.”")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .hSpacing(.center)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
    }
}

//MARK: - Add Popup

struct CentrePopup_AddGratitudeEntry: CenterPopup {
    @Environment(\.modelContext) var modelContext
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.colorScheme) var colorScheme
    
    var onDone: () -> Void
    
    @State private var entry1: String = ""
    @State private var entry2: String = ""
    @State private var entry3: String = ""
    @State private var notes: String = ""
    
    @State private var error: String?
    
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
                    Task {
                        let result = await saveGratitudeEntry()
                        if result.isSuccess {
                            await dismissLastPopup()
                            onDone()
                        } else {
                            error = "Error saving entry. Please try again."
                        }
                    }
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
    
    func saveGratitudeEntry() async-> Result<Void, Error> {
        let newEntry = DailyGratitude(entry1: entry1, entry2: entry2, entry3: entry3, notes: notes)
        modelContext.insert(newEntry)
        do {
            try modelContext.save()
            return .success(())
        } catch {
            print("Error saving new gratitude entry: \(error)")
            return .failure(error)
        }
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
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




//MARK: - Preview

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
