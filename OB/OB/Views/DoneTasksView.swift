//
//  DoneTasksView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct DoneTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]

    @State private var editingTask: TaskItem?

    private var doneTasks: [TaskItem] {
        tasks
            .filter { $0.status == .done }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        Group {
            if doneTasks.isEmpty {
                ContentUnavailableView(
                    "Пока пусто",
                    systemImage: "checkmark.circle",
                    description: Text("Выполненные задачи появятся здесь.")
                )
            } else {
                List {
                    ForEach(doneTasks) { task in
                        HStack(spacing: 12) {
                            Button {
                                uncheck(task)
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .strikethrough()
                                if let completedAt = task.completedAt {
                                    Text("Выполнено \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTask = task
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTask(task)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Выполнено")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTask) { task in
            TaskEditView(task: task)
        }
    }

    private func uncheck(_ task: TaskItem) {
        task.status = .todo
        task.completedAt = nil
        DayPlan.existingToday(in: modelContext)?.items.removeAll { $0.taskId == task.id }
        try? modelContext.save()
    }

    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        DoneTasksView()
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
