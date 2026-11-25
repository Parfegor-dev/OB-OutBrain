//
//  ProjectsView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]

    @State private var showAddSheet = false

    private var sortedProjects: [Project] {
        projects.sorted { lhs, rhs in
            if (lhs.status == .active) != (rhs.status == .active) {
                return lhs.status == .active
            }
            return (lhs.deadline ?? .distantFuture) < (rhs.deadline ?? .distantFuture)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "Нет проектов",
                        systemImage: "folder",
                        description: Text("Проект — это цель с дедлайном и следующим шагом.")
                    )
                } else {
                    List {
                        ForEach(sortedProjects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(project.title)
                                            .font(.headline)
                                        Spacer()
                                        statusBadge(project.status)
                                    }
                                    if let deadline = project.deadline {
                                        Label(deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let nextStep = project.nextStep, !nextStep.isEmpty {
                                        Label(nextStep, systemImage: "arrow.right.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Проекты")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Новый проект", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                ProjectFormView()
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: ProjectStatus) -> some View {
        switch status {
        case .active:
            Text("активен").font(.caption).foregroundStyle(.green)
        case .paused:
            Text("пауза").font(.caption).foregroundStyle(.orange)
        case .done:
            Text("завершён").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let project = sortedProjects[index]
            NotificationService.cancelReminders(ownerId: project.id)
            modelContext.delete(project)
        }
        try? modelContext.save()
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: Project.self, inMemory: true)
}
