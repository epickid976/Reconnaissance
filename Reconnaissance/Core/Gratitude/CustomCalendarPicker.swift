//
//  CustomCalendarPicker.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/12/24.
//

import SwiftUI

//MARK: - Custom Calendar

struct CustomDateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    var onDone: () -> Void
    
    @State private var hoverDate: Date? // For dynamic range previews
    @State private var currentMonth: Date = Date() // Tracks the displayed month
    
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 20) {
            // Title & Selected Dates
            VStack {
                Text("Select Date Range")
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    dateLabel(title: NSLocalizedString("Start Date", comment: ""), date: startDate)
                    Spacer()
                    dateLabel(title: NSLocalizedString("End Date", comment: ""), date: endDate)
                }
                .padding(.horizontal)
            }
            
            // Calendar with transitions
            VStack(spacing: 10) {
                calendarHeader()

                // Weekday symbols
                HStack(spacing: 0) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }

                // Days grid with swipe gestures
                ZStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(calendarDays(), id: \.self) { day in
                            calendarDayView(day: day)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading))
                    )
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < 0 { // Swipe left
                                withAnimation {
                                    HapticManager.shared.trigger(.lightImpact)
                                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                                }
                            } else if value.translation.width > 0 { // Swipe right
                                withAnimation {
                                    HapticManager.shared.trigger(.lightImpact)
                                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                                }
                            }
                        }
                )
            }
            .animation(.spring(), value: currentMonth) // Ensure smooth animations for swipes
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(.horizontal)
            
            // Action buttons
            HStack {
                Button(action: {
                    withAnimation {
                        HapticManager.shared.trigger(.lightImpact)
                        startDate = nil
                        endDate = nil
                    }
                }) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.2))
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    onDone()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                        )
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Calendar Header
    @ViewBuilder
    private func calendarHeader() -> some View {
        HStack {
            Button(action: {
                withAnimation {
                    HapticManager.shared.trigger(.lightImpact)
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(currentMonth, formatter: DateFormatter.monthAndYear)
                .font(.headline)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < 0 {
                                // Swipe left: next month
                                withAnimation {
                                    HapticManager.shared.trigger(.lightImpact)
                                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                                }
                            } else if value.translation.width > 0 {
                                // Swipe right: previous month
                                withAnimation {
                                    HapticManager.shared.trigger(.lightImpact)
                                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                                }
                            }
                        }
                )

            Spacer()

            Button(action: {
                withAnimation {
                    HapticManager.shared.trigger(.lightImpact)
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Individual Day View
    private func calendarDayView(day: Date?) -> some View {
        Group {
            if let day = day {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline)
                    .fontWeight(calendar.isDateInToday(day) ? .semibold : .regular)
                    .foregroundColor(textColor(for: day))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor(for: day))
                    )
                    .onTapGesture {
                        withAnimation {
                            HapticManager.shared.trigger(.lightImpact)
                            handleDateSelection(day)
                        }
                    }
                    // Slight scale effect on hover (macOS/Catalyst)
                    .scaleEffect(hoverDate == day ? 1.1 : 1)
                    .onHover { isHovering in
                        hoverDate = isHovering ? day : nil
                    }
            } else {
                Color.clear
            }
        }
    }
    
    // Customize text color for a day cell
    private func textColor(for date: Date) -> Color {
        if calendar.isDateInToday(date) {
            return .white
        } else {
            return .primary
        }
    }
    
    // Title + date label
    private func dateLabel(title: String, date: Date?) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(date.map { DateFormatter.medium.string(from: $0) } ?? NSLocalizedString("Not selected", comment: ""))
                .font(.body)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Calendar Days Logic
    private func calendarDays() -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let firstDayOffset = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let prevMonthPadding = firstDayOffset < 0 ? 7 + firstDayOffset : firstDayOffset
        
        var days: [Date?] = Array(repeating: nil, count: prevMonthPadding)
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        return days
    }
    
    private func handleDateSelection(_ date: Date) {
        // Simple toggle logic:
        if startDate == nil || (startDate != nil && endDate != nil) {
            startDate = date
            endDate = nil
        } else if let start = startDate, date < start {
            startDate = date
        } else {
            endDate = date
        }
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if calendar.isDateInToday(date) {
            return Color.green.opacity(0.5)
        } else if date == startDate || date == endDate {
            return Color.blue.opacity(0.5)
        } else if let start = startDate, let end = endDate, date >= start && date <= end {
            return Color.blue.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
