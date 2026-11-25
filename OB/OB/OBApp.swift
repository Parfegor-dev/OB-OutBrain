//
//  OBApp.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

@main
struct OBApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Capture.self,
            TaskItem.self,
            Project.self,
            Habit.self,
            Idea.self,
            DayPlan.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .task {
                    NotificationService.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
