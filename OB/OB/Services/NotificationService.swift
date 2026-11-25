//
//  NotificationService.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import UserNotifications

enum NotificationService {
    private static let nextStepId = "next-step"
    private static let reminderPrefix = "reminder-"

    static var nextStepDelay: TimeInterval = 60 * 60

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Следующий шаг: один активный шаг за раз (SPEC §3.3)

    static func scheduleNextStep(title: String, estimateMin: Int?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [nextStepId])
        let content = UNMutableNotificationContent()
        content.title = "Следующий шаг"
        if let estimateMin {
            content.body = "\(title) — \(estimateMin) мин"
        } else {
            content.body = title
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: nextStepDelay, repeats: false)
        center.add(UNNotificationRequest(identifier: nextStepId, content: content, trigger: trigger)) { error in
            if let error {
                print("[notifications] add next-step failed: \(error.localizedDescription)")
            }
        }
        debugPrintPending()
    }

    static func cancelNextStep() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [nextStepId])
    }

    // Напоминания о дедлайнах задач, шагов и проектов (SPEC §5)

    static func syncReminders(for task: TaskItem) {
        let active = task.status != .done && task.status != .cancelled
        syncReminders(ownerId: task.id, active: active, reminders: task.reminders, parentTitle: task.title, deadline: task.deadline)
    }

    static func syncReminders(for project: Project) {
        syncReminders(ownerId: project.id, active: project.status != .done, reminders: project.reminders, parentTitle: project.title, deadline: project.deadline)
    }

    static func cancelReminders(ownerId: UUID) {
        syncReminders(ownerId: ownerId, active: false, reminders: [], parentTitle: "", deadline: nil)
    }

    // Отмена старых и постановка новых — последовательно в одном колбэке, чтобы не было гонки
    private static func syncReminders(ownerId: UUID, active: Bool, reminders: [Reminder], parentTitle: String, deadline: Date?) {
        let center = UNUserNotificationCenter.current()
        let prefix = reminderPrefix + ownerId.uuidString + "-"
        center.getPendingNotificationRequests { requests in
            let staleIds = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: staleIds)

            guard active, let deadline else {
                debugPrintPending()
                return
            }
            for reminder in reminders {
                let interval = reminder.fireAt.timeIntervalSinceNow
                guard interval > 0 else { continue }
                let content = UNMutableNotificationContent()
                content.title = "Дедлайн: \(parentTitle)"
                content.body = deadline.formatted(date: .abbreviated, time: .shortened)
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let id = prefix + reminder.id.uuidString
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { error in
                    if let error {
                        print("[notifications] add \(id) failed: \(error.localizedDescription)")
                    }
                }
            }
            debugPrintPending()
        }
    }

    static func debugPrintPending() {
        #if DEBUG
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("[notifications] pending: \(requests.count)")
            for request in requests {
                let fireDate = (request.trigger as? UNTimeIntervalNotificationTrigger)
                    .map { "\(Date().addingTimeInterval($0.timeInterval))" } ?? "?"
                print("[notifications]   \(request.identifier) → \(fireDate) — \(request.content.body)")
            }
        }
        #endif
    }
}
