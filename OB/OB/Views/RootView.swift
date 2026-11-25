//
//  RootView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    enum Tab {
        case capture, today, projects, parking
    }

    @State private var selectedTab: Tab = .capture

    var body: some View {
        TabView(selection: $selectedTab) {
            CaptureView()
                .tabItem { Label("Захват", systemImage: "tray.and.arrow.down") }
                .tag(Tab.capture)

            TodayView()
                .tabItem { Label("Сегодня", systemImage: "sun.max") }
                .tag(Tab.today)

            ProjectsView()
                .tabItem { Label("Проекты", systemImage: "folder") }
                .tag(Tab.projects)

            ParkingView()
                .tabItem { Label("Парковка", systemImage: "parkingsign") }
                .tag(Tab.parking)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Capture.self, inMemory: true)
}
