//
//  Project.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

enum ProjectStatus: String, Codable {
    case active
    case paused
    case done
}

@Model
final class Project {
    var id: UUID
    var title: String
    var deadline: Date?
    var status: ProjectStatus = ProjectStatus.active
    var nextStep: String?
    var contextNotes: String = ""
    var reminders: [Reminder] = []

    init(id: UUID = UUID(), title: String, deadline: Date? = nil, status: ProjectStatus = .active, nextStep: String? = nil, contextNotes: String = "", reminders: [Reminder] = []) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.status = status
        self.nextStep = nextStep
        self.contextNotes = contextNotes
        self.reminders = reminders
    }
}
