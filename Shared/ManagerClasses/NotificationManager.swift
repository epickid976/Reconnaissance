//
//  NotificationManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 1/20/25.
//

import UserNotifications
import SwiftData

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    /// Request notification permission
    func requestPermission() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        if !granted {
            throw NSError(domain: "NotificationPermission", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notification permission not granted."])
        }
    }

    /// Schedule a notification
    func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Remove a scheduled notification
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Remove all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

extension NotificationManager {
    /// Schedule daily reminder at 8 PM if no entry exists
    func scheduleDailyReminder() {
        Task {
            let entryExists = await checkIfEntryExists(for: Date())
            if !entryExists {
                scheduleNotification(
                    id: "dailyReminder",
                    title: "Don't Forget Your Gratitude Entry",
                    body: "You haven't made an entry today. Take a moment to reflect!",
                    date: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
                )
            }
        }
    }

    /// Schedule custom reminder at user-specified time
    func scheduleCustomReminder(at time: Date) {
        cancelNotification(id: "customReminder")
        scheduleNotification(
            id: "customReminder",
            title: "Custom Reminder",
            body: "Time to reflect on your gratitude!",
            date: time
        )
    }

    /// Check if an entry exists for a given date
    private func checkIfEntryExists(for date: Date) async -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let context = SharedModelContainer.container.mainContext

        do {
            let request = FetchDescriptor<DailyGratitude>(
                predicate: #Predicate { gratitude in
                    gratitude.date >= startOfDay && gratitude.date < endOfDay
                }
            )

            let results = try context.fetch(request)
            return !results.isEmpty
        } catch {
            print("Error fetching DailyGratitude entries: \(error.localizedDescription)")
            return false
        }
    }
}
