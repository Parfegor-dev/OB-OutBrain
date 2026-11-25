//
//  Capture.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import Foundation
import SwiftData

@Model
final class Capture {
    var id: UUID
    var rawText: String
    var createdAt: Date
    var processed: Bool = false

    init(id: UUID = UUID(), rawText: String, createdAt: Date = Date(), processed: Bool = false) {
        self.id = id
        self.rawText = rawText
        self.createdAt = createdAt
        self.processed = processed
    }
}
