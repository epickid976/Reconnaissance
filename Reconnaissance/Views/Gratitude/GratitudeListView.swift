//
//  GratitudeListView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/10/24.
//
import SwiftUI
import SwiftData

//MARK: - List View

struct GratitudeListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var path: NavigationPath

    @State private var selectedDate = Date()
    @Query(sort: \DailyGratitude.date, order: .reverse)
    private var gratitudes: [DailyGratitude]

    private var calendar = Calendar.current
    private var todayGratitude: DailyGratitude? {
        gratitudes.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    @State private var isCalendarCompacted: Bool = false // Track compacted state
    @State private var calendarHeight: CGFloat = 300 // Initial height of the calendar
    @State private var noteText: String = "" // Text for the note section

    public init(path: Binding<NavigationPath>) {
            _path = path
        }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar View
                CalendarView(selectedDate: $selectedDate, isCompacted: $isCalendarCompacted)
                    .frame(height: isCalendarCompacted ? 100 : 300)
                    .background(Color.primary.colorInvert())
                    .padding()
                    //.zIndex(1) // Keep calendar above content
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                withAnimation {
                                    if value.translation.height < -50 {
                                        isCalendarCompacted = true
                                    } else if value.translation.height > 50 {
                                        isCalendarCompacted = false
                                    }
                                }
                            }
                    )
                    .vSpacing(.top)

                // Gratitude Cell for Today's Entry
                if let gratitude = todayGratitude {
                    ScrollView {
                        if isCalendarCompacted {
                            Spacer()
                                .frame(height: 20)
                        } else {
                            Spacer()
                        }
                        VStack(spacing: 16) {
                            GratitudeCell(gratitude: gratitude, mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: 300))
                                .modifier(ScrollTransitionModifier())
                                .transition(.customBackInsertion)
                            
                            ZStack(alignment: .topLeading) {
                                TextField("Notes. Write something here...", text: $noteText, axis: .vertical)
                                    .lineLimit(1...6)  // Allow 3-6 lines before scrolling
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(noteText.isEmpty ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.8), lineWidth: 1)
                                    )
                                    .cornerRadius(20)
                                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3), radius: 6, x: 0, y: 4)
                            }
                            .padding(.horizontal, 16)
                            .animation(.spring(), value: noteText)
                        }
                    }
                    .vSpacing(.top)
                } else {
                    Text("No entry for today.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .vSpacing(.top)
                }
            }
            .navigationTitle("Today's Gratitude")
            .navigationBarTitleDisplayMode(.large)
            //.padding(.vertical, 16)
        }
    }

    private func saveNoteForToday(gratitude: DailyGratitude) {
        // Save the note to the gratitude entry
        gratitude.notes = noteText
        do {
            try modelContext.save()
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isCompacted: Bool // Binding for compacted state

    private let currentDate = Date()
    private let calendar = Calendar.current
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)

    @State private var animatingMonth: Bool = false // Controls month animation

    var body: some View {
        VStack(spacing: isCompacted ? 8 : 16) {
            // Month and Year Header
            HStack {
                Button(action: isCompacted ? previousWeek : previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text(isCompacted ? weekRange(for: selectedDate) : monthAndYear(for: selectedDate))
                    .font(isCompacted ? .headline : .title3)
                    .bold()
                    .foregroundColor(.primary)
                    .opacity(animatingMonth ? 0.5 : 1)
                    .animation(.easeInOut, value: animatingMonth)
                Spacer()
                Button(action: isCompacted ? nextWeek : nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)

            // Weekday Header
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays(), id: \.self) { day in
                    Text(day)
                        .font(.footnote)
                        .bold()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Dates Grid: Month or Week
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(isCompacted ? daysInWeek(for: selectedDate) : daysInMonth(for: selectedDate), id: \.self) { date in
                    Text("\(calendar.component(.day, from: date))")
                        .font(.body)
                        .bold()
                        .foregroundColor(isSameDay(date, selectedDate) ? .white : .primary)
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .background(
                            Circle()
                                .fill(isSameDay(date, selectedDate) ? Color.blue : Color.clear)
                        )
                        .clipShape(Circle())
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                selectedDate = date
                            }
                        }
                        .opacity(isCompacted || isSameMonth(date, selectedDate) ? 1 : 0.4) // Dim out-of-month dates in full view
                        .disabled(!isSameMonth(date, selectedDate) && !isCompacted) // Disable out-of-month dates in full view
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        .animation(.easeInOut, value: selectedDate)
    }

    // Helper Functions
    private func monthAndYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func weekRange(for date: Date) -> String {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: date)?.start else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    private func weekdays() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }

    private func daysInMonth(for date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth) }
    }

    private func daysInWeek(for date: Date) -> [Date] {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    private func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }

    private func previousWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) else { return }
        withAnimation(.easeInOut) {
            selectedDate = newDate
        }
    }

    private func nextWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) else { return }
        withAnimation(.easeInOut) {
            selectedDate = newDate
        }
    }

    private func previousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) else { return }
        withAnimation(.easeInOut) {
            selectedDate = newDate
        }
    }

    private func nextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) else { return }
        withAnimation(.easeInOut) {
            selectedDate = newDate
        }
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
