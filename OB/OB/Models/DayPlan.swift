//
//  DayPlan.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

struct PlanItem: Codable, Hashable {
    var taskId: UUID
    var timeBlock: String?
    var approved: Bool
}

@Model
final class DayPlan {
    var id: UUID
    var date: Date
    var items: [PlanItem] = []

    init(id: UUID = UUID(), date: Date, items: [PlanItem] = []) {
        self.id = id
        self.date = date
        self.items = items
    }
}

extension DayPlan {
    static func existingToday(in context: ModelContext) -> DayPlan? {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<DayPlan> { $0.date == startOfDay }
        return try? context.fetch(FetchDescriptor<DayPlan>(predicate: predicate)).first
    }

    static func today(in context: ModelContext) -> DayPlan {
        if let existing = existingToday(in: context) {
            return existing
        }
        let plan = DayPlan(date: Calendar.current.startOfDay(for: Date()))
        context.insert(plan)
        return plan
    }
}
