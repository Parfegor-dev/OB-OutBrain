//
//  Idea.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

enum IdeaStatus: String, Codable {
    case parked
    case ready
    case dropped
}

@Model
final class Idea {
    var id: UUID
    var title: String
    var notes: String = ""
    var createdAt: Date
    var status: IdeaStatus = IdeaStatus.parked

    init(id: UUID = UUID(), title: String, notes: String = "", createdAt: Date = Date(), status: IdeaStatus = .parked) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.status = status
    }
}
