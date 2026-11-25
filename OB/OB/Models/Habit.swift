//
//  Habit.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    var frequencyRule: String
    var active: Bool = true

    init(id: UUID = UUID(), title: String, frequencyRule: String, active: Bool = true) {
        self.id = id
        self.title = title
        self.frequencyRule = frequencyRule
        self.active = active
    }
}
