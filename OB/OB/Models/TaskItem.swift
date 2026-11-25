//
//  TaskItem.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

enum TaskPriority: String, Codable {
    case low
    case medium
    case high
}

enum TaskStatus: String, Codable {
    case todo
    case inProgress
    case done
    case cancelled
}

@Model
final class TaskItem {
    var id: UUID
    var projectId: UUID?
    var title: String
    var notes: String = ""
    var deadline: Date?
    var priority: TaskPriority = TaskPriority.medium
    var status: TaskStatus = TaskStatus.todo
    var estimateMin: Int?
    var sourceCaptureId: UUID?
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, notes: String = "", projectId: UUID? = nil, deadline: Date? = nil, priority: TaskPriority = .medium, status: TaskStatus = .todo, estimateMin: Int? = nil, sourceCaptureId: UUID? = nil, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.projectId = projectId
        self.deadline = deadline
        self.priority = priority
        self.status = status
        self.estimateMin = estimateMin
        self.sourceCaptureId = sourceCaptureId
        self.completedAt = completedAt
    }
}
