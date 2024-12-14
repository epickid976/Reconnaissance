//
//  Extensions.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/25/24.
//

import Foundation
import SwiftUI
import NavigationTransitions
import UniformTypeIdentifiers

// MARK: - Array Extensions

extension Array {
    /// Filters the array in place, removing elements that don't meet the specified criteria.
    /// - Parameter isIncluded: A closure that determines if an element should be kept.
    mutating func filterInPlace(isIncluded: (Element) throws -> Bool) rethrows {
        var writeIndex = self.startIndex
        for readIndex in self.indices {
            let element = self[readIndex]
            let include = try isIncluded(element)
            if include {
                if writeIndex != readIndex {
                    self[writeIndex] = element
                }
                writeIndex = self.index(after: writeIndex)
            }
        }
        self.removeLast(self.distance(from: writeIndex, to: self.endIndex))
    }
}

extension Array {
    /// Removes elements in place based on a specified condition.
    /// - Parameter shouldRemove: Closure returning true for elements to be removed.
    mutating func removeInPlace(where shouldRemove: (Element) throws -> Bool) rethrows {
        var writeIndex = self.startIndex
        for readIndex in self.indices {
            let element = self[readIndex]
            if try shouldRemove(element) { continue }
            if writeIndex != readIndex { self[writeIndex] = element }
            writeIndex = self.index(after: writeIndex)
        }
        removeLast(self.distance(from: writeIndex, to: self.endIndex))
    }
}

extension Array {
    /// Splits the array into chunks of a specified size.
    /// - Parameter size: The size of each chunk.
    /// - Returns: An array of arrays where each inner array contains a chunk of the original array.
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        var startIndex = 0
        
        while startIndex < self.count {
            let endIndex = Swift.min(startIndex + size, self.count)
            chunks.append(Array(self[startIndex..<endIndex]))
            startIndex += size
        }
        
        return chunks
    }
}

extension Array {
    /// Divides the array into subarrays of a specific size.
    /// - Parameter smallSize: Max size for each subarray.
    /// - Returns: An array of arrays with each inner array containing up to `smallSize` elements.
    func divideIn(_ smallSize: Int) -> [[Element]] {
        var sublistList = [[Element]]()
        var start = 0
        while start < self.count {
            let end = Swift.min(start + smallSize, self.count)
            let actual = Array(self[start..<end])
            sublistList.append(actual)
            start += smallSize
        }
        return sublistList
    }
}

extension Array {
    /// Returns an array with unique elements based on a specified property.
    /// - Parameter map: Closure mapping elements to a unique identifier.
    /// - Returns: An array with unique elements, preserving order.
    func unique<T: Hashable>(map: ((Element) -> (T))) -> [Element] {
        var set = Set<T>() // Keeps unique values for fast checking
        var arrayOrdered = [Element]() // Maintains order
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }
        return arrayOrdered
    }
}

extension Array where Element == String {
    /// Converts the array of strings to a JSON string.
    /// - Returns: JSON string representation of the array or nil if conversion fails.
    func toJSON() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self),
              var string = String(data: data, encoding: .utf8) else {
            return nil
        }
        // Remove unwanted escaping
        string = string.replacingOccurrences(of: "\\", with: "")
        return string
    }
}

// MARK: - String Extensions

extension String {
    /// Validates if the string is in phone number format.
    /// - Returns: True if the string matches a standard phone format.
    func isValidPhoneNumber() -> Bool {
        let phoneRegex = "^\\(\\d{3}\\) \\d{3}-\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }
}

extension String {
    /// Removes special formatting characters from the string.
    /// - Returns: String without formatting characters like '(', ')', '-', and spaces.
    func removeFormatting() -> String {
        return replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

extension String {
    /// Formats a raw number string into a standard phone format.
    /// - Returns: Formatted phone number, e.g., "(XXX) XXX-XXXX".
    func formatPhoneNumber() -> String {
        let cleanNumber = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var startIndex = cleanNumber.startIndex
        let endIndex = cleanNumber.endIndex
        for char in mask where startIndex < endIndex {
            if char == "X" {
                result.append(cleanNumber[startIndex])
                startIndex = cleanNumber.index(after: startIndex)
            } else {
                result.append(char)
            }
        }
        return result
    }
}

extension String {
    /// Replaces certain characters with their browser-safe equivalents.
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
    }
}

// MARK: - Date Extensions and Date-related Functions

/// Checks if a given date is within the last two weeks.
func isInLastTwoWeeks(_ visitDate: Date) -> Bool {
    let today = Date()
    let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!
    return twoWeeksAgo <= visitDate && visitDate <= today
}

extension Date {
    /// Converts the date to milliseconds since 1970.
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    /// Creates a date from milliseconds since 1970.
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension Calendar {
    private var currentDate: Date { return Date() }

    /// Determines if a date falls within the current week.
    func isDateInThisWeek(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
    }

    /// Determines if a date falls within the current month.
    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .month)
    }

    /// Determines if a date falls within the current year.
    func isDateInThisYear(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .year)
    }
}

extension Calendar {
    
    func isDateInNextWeek(_ date: Date) -> Bool {
        guard let nextWeek = self.date(byAdding: DateComponents(weekOfYear: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
    }
    
    func isDateInNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    func isDateInFollowingMonth(_ date: Date) -> Bool {
        guard let followingMonth = self.date(byAdding: DateComponents(month: 2), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: followingMonth, toGranularity: .month)
    }
}

@MainActor
func formattedDate(date: Date, withTime: Bool = true) -> String {
    let formatter1 = DateFormatter()
    
    if withTime {
        if  Calendar.current.isDateInToday(date) {
            formatter1.dateFormat = "HH:mm a"
            return NSLocalizedString("Today ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInYesterday(date){
            formatter1.dateFormat = "HH:mm a"
            return NSLocalizedString("Yesterday ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInThisWeek(date) {
            formatter1.dateFormat = "EEEE HH:mm a"
            return  formatter1.string(from: date)
        } else {
            formatter1.dateFormat = "dd MMM yyyy hh:mm a"
            return  formatter1.string(from: date)
        }
    } else {
        if  Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date){
            return "Yesterday"
        } else if Calendar.current.isDateInThisWeek(date) {
            formatter1.dateFormat = "EEEE"
            return  formatter1.string(from: date)
        } else {
            formatter1.dateFormat = "MM-dd-yyyy"
            return  formatter1.string(from: date)
        }
    }
}

func daysSince(date: Date) -> Int {
    let calendar = Calendar.current
    let currentDate = Date()
    
    let components = calendar.dateComponents([.day], from: date, to: currentDate)
    return components.day ?? 0 // Default to 0 if the calculation fails
}


//MARK: - Rounded Corner Extension
/// Rounded Corner and Animation Functions
struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//MARK: - Animations and Transitions
extension AnyNavigationTransition {
    static var zoom: Self {
        .init(Zoom())
    }
}

struct Zoom: NavigationTransitions.NavigationTransitionProtocol {
    var body: some NavigationTransitions.NavigationTransitionProtocol {
        MirrorPush {
            Scale(0.5)
            OnInsertion {
                ZPosition(1)
                Opacity()
            }
        }
    }
}

extension SwiftUI.Animation {
    static var sophisticated: SwiftUI.Animation {
        return .interpolatingSpring(mass: 1, stiffness: 170, damping: 16, initialVelocity: 0)
            .speed(1.2)
    }
}

extension AnyTransition {
    static var customBackInsertion: AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.opacity
                .combined(with: .scale(scale: 0.8, anchor: .center))
                .combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
        .animation(.spring())
    }
}

//MARK: - Utility Functions
// Additional utility functions
@MainActor
func openMail(emailTo:String, subject: String, body: String) {
    if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())&body=\(body.fixToBrowserString())"),
       UIApplication.shared.canOpenURL(url)
    {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

@MainActor
func openMaps(searchQuery: String) {
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encodedQuery)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
    }

@MainActor
func resignFirstResponderManually() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

//MARK: - Column View Properties

private struct ColumnViewPreferenceKey: EnvironmentKey {
    static let defaultValue = true // Default to column view on
}


class ColumnViewModel: ObservableObject {
    
    @AppStorage("name") var name = "mon ami(e)"
    
    @AppStorage("columnViewPreference") var isColumnViewEnabled = true

    @AppStorage("hapticFeedback") var hapticFeedback = true
    
}

//MARK: - Other Environment Values
struct ViewOffsetKey: PreferenceKey, Sendable {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

extension EnvironmentValues {
    var columnViewPreference: Bool {
        get { self[ColumnViewPreferenceKey.self] }
        set { self[ColumnViewPreferenceKey.self] = newValue }
    }
}

extension Binding where Value == Bool {
    // nagative bool binding same as `!Value`
    var not: Binding<Value> {
        Binding<Value> (
            get: { !self.wrappedValue },
            set: { self.wrappedValue = $0}
        )
    }
}

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: some View {
        build()
    }
}
public struct MyLazyNavigationLink<Label: View, Destination: View>: View {
    var destination: () -> Destination
    var label: () -> Label
    
    public init(@ViewBuilder destination: @escaping () -> Destination,
                @ViewBuilder label: @escaping () -> Label) {
        self.destination = destination
        self.label = label
    }
    
    public var body: some View {
        NavigationLink {
            LazyView {
                destination()
            }
        } label: {
            label()
        }
    }
    
    private struct LazyView<Content: View>: View {
        var content: () -> Content
        
        var body: some View {
            content()
        }
    }
}


// MARK: - Global Actors
@globalActor actor SyncActor: GlobalActor {
    static var shared = SyncActor()
}

@globalActor actor BackgroundActor: GlobalActor {
    static var shared = BackgroundActor()
}

extension BackgroundActor {
    // Custom run function
    static func run<T>(_ operation: @escaping () async -> T) async -> T {
        await operation()
    }
}

@MainActor
final class GratitudeViewState: ObservableObject {
    static let shared = GratitudeViewState()

    @Published var isShowingHistory: Bool = false
}

@MainActor
func shareApp() {
    let items: [Any] = ["Check out this app!", URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103?l=fr-FR")!]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Find the active UIWindowScene
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            activityViewController.popoverPresentationController?.sourceView = rootVC.view // Required for iPad
            rootVC.present(activityViewController, animated: true, completion: nil)

            if UIDevice.current.userInterfaceIdiom == .pad {
                // Configure popover presentation for iPad
                activityViewController.popoverPresentationController?.sourceView = rootVC.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(
                    x: UIScreen.main.bounds.width / 2.1,
                    y: UIScreen.main.bounds.height / 1.3,
                    width: 1,
                    height: 1
                )
            }
        }
}



@MainActor
func presentShareSheet(with fileURL: URL) {
    let items: [Any] = [fileURL]
    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

    // Find the active UIWindowScene
    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {

        activityViewController.popoverPresentationController?.sourceView = rootVC.view // Required for iPad
        rootVC.present(activityViewController, animated: true, completion: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            // Configure popover presentation for iPad
            activityViewController.popoverPresentationController?.sourceView = rootVC.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(
                x: UIScreen.main.bounds.width / 2.1,
                y: UIScreen.main.bounds.height / 1.3,
                width: 1,
                height: 1
            )
        }
    }
}

@MainActor
func presentDocumentPicker(for format: String, completion: @escaping (URL) -> Void) {
    let allowedTypes: [UTType] = format == "json" ? [.json] : [.commaSeparatedText]
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
    documentPicker.allowsMultipleSelection = false
    documentPicker.delegate = DocumentPickerDelegate { url in
        completion(url)
    }

    // Find the active UIWindowScene
    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        rootVC.present(documentPicker, animated: true, completion: nil)
    }
}

// Delegate for Document Picker
class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void

    init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick(url)
    }
}
