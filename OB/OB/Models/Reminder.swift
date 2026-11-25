//
//  Reminder.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation

struct Reminder: Codable, Hashable, Identifiable {
    var id: UUID
    var fireAt: Date
    var isAuto: Bool

    init(id: UUID = UUID(), fireAt: Date, isAuto: Bool) {
        self.id = id
        self.fireAt = fireAt
        self.isAuto = isAuto
    }
}

extension Reminder {
    // Дефолтные напоминания при установке дедлайна: −3 дня, −1 день, −1,5 часа; прошедшие пропускаются
    static func defaults(for deadline: Date, now: Date = Date()) -> [Reminder] {
        let offsets: [TimeInterval] = [-3 * 24 * 60 * 60, -1 * 24 * 60 * 60, -1.5 * 60 * 60]
        return offsets.compactMap { offset in
            let fireAt = deadline.addingTimeInterval(offset)
            guard fireAt > now else { return nil }
            return Reminder(fireAt: fireAt, isAuto: true)
        }
    }

    // Дедлайн изменился: авто пересчитываются, ручные сохраняются; дедлайн снят — список пуст
    static func recomputed(current: [Reminder], deadline: Date?) -> [Reminder] {
        guard let deadline else { return [] }
        return current.filter { !$0.isAuto } + defaults(for: deadline)
    }

    // «за 3 дня до дедлайна», «за 1 час 30 минут до дедлайна»
    static func offsetText(fireAt: Date, deadline: Date) -> String {
        let interval = deadline.timeIntervalSince(fireAt)
        guard interval > 0 else { return "после дедлайна" }
        let totalMinutes = Int((interval / 60).rounded())
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60
        var parts: [String] = []
        if days > 0 {
            parts.append("\(days) \(plural(days, "день", "дня", "дней"))")
        }
        if hours > 0 {
            parts.append("\(hours) \(plural(hours, "час", "часа", "часов"))")
        }
        if minutes > 0 && days == 0 {
            parts.append("\(minutes) \(plural(minutes, "минута", "минуты", "минут"))")
        }
        guard !parts.isEmpty else { return "в момент дедлайна" }
        return "за " + parts.joined(separator: " ") + " до дедлайна"
    }

    private static func plural(_ value: Int, _ one: String, _ few: String, _ many: String) -> String {
        let mod100 = abs(value) % 100
        let mod10 = mod100 % 10
        if (11...14).contains(mod100) { return many }
        if mod10 == 1 { return one }
        if (2...4).contains(mod10) { return few }
        return many
    }
}
