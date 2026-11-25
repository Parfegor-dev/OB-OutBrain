//
//  TaskEditView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct TaskEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem?

    @Query private var projects: [Project]

    @State private var title: String
    @State private var priority: TaskPriority
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var estimateText: String
    @State private var projectId: UUID?
    @State private var notes: String
    @State private var reminders: [Reminder]

    init(task: TaskItem? = nil) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _priority = State(initialValue: task?.priority ?? TaskPriority.medium)
        _hasDeadline = State(initialValue: task.map { $0.deadline != nil } ?? false)
        _deadline = State(initialValue: task?.deadline ?? Date())
        _estimateText = State(initialValue: task?.estimateMin.map(String.init) ?? "")
        _projectId = State(initialValue: task?.projectId)
        _notes = State(initialValue: task?.notes ?? "")
        _reminders = State(initialValue: task?.reminders ?? [])
    }

    private var activeProjects: [Project] {
        projects.filter { $0.status == .active }.sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $title)
                }
                Section {
                    Picker("Приоритет", selection: $priority) {
                        Text("Низкий").tag(TaskPriority.low)
                        Text("Средний").tag(TaskPriority.medium)
                        Text("Высокий (фокус)").tag(TaskPriority.high)
                    }
                    Toggle("Дедлайн", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Дата и время", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                        NavigationLink {
                            RemindersView(reminders: $reminders, parentTitle: title, deadline: deadline)
                        } label: {
                            HStack {
                                Text("Напоминания")
                                Spacer()
                                Text("\(reminders.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    TextField("Оценка, мин (необязательно)", text: $estimateText)
                        .keyboardType(.numberPad)
                }
                Section {
                    Picker("Проект", selection: $projectId) {
                        Text("Без проекта").tag(UUID?.none)
                        ForEach(activeProjects) { project in
                            Text(project.title).tag(UUID?.some(project.id))
                        }
                    }
                }
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(task == nil ? "Новая задача" : "Задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: hasDeadline) { recomputeReminders() }
            .onChange(of: deadline) { recomputeReminders() }
        }
    }

    private func recomputeReminders() {
        reminders = Reminder.recomputed(current: reminders, deadline: hasDeadline ? deadline : nil)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let savedTask: TaskItem
        if let task {
            task.title = trimmed
            task.priority = priority
            task.deadline = hasDeadline ? deadline : nil
            task.estimateMin = Int(estimateText)
            task.projectId = projectId
            task.notes = notes
            task.reminders = reminders
            savedTask = task
        } else {
            let newTask = TaskItem(
                title: trimmed,
                notes: notes,
                projectId: projectId,
                deadline: hasDeadline ? deadline : nil,
                priority: priority,
                estimateMin: Int(estimateText),
                reminders: reminders
            )
            modelContext.insert(newTask)
            let plan = DayPlan.today(in: modelContext)
            plan.items.append(PlanItem(taskId: newTask.id, timeBlock: nil, approved: true))
            savedTask = newTask
        }
        try? modelContext.save()
        NotificationService.syncReminders(for: savedTask)
        dismiss()
    }
}

#Preview {
    TaskEditView()
        .modelContainer(for: [TaskItem.self, Project.self, DayPlan.self], inMemory: true)
}
