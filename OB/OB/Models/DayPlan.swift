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
