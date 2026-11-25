//
//  StepFormView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct StepFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let projectId: UUID?
    let step: TaskItem?

    @State private var title: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var reminders: [Reminder]

    init(projectId: UUID? = nil, step: TaskItem? = nil) {
        self.projectId = projectId
        self.step = step
        _title = State(initialValue: step?.title ?? "")
        _hasDeadline = State(initialValue: step.map { $0.deadline != nil } ?? false)
        _deadline = State(initialValue: step?.deadline ?? Date())
        _reminders = State(initialValue: step?.reminders ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $title)
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
            }
            .navigationTitle(step == nil ? "Новый шаг" : "Шаг")
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
        let savedStep: TaskItem
        if let step {
            step.title = trimmed
            step.deadline = hasDeadline ? deadline : nil
            step.reminders = reminders
            savedStep = step
        } else {
            let newStep = TaskItem(title: trimmed, projectId: projectId, deadline: hasDeadline ? deadline : nil, reminders: reminders)
            modelContext.insert(newStep)
            savedStep = newStep
        }
        try? modelContext.save()
        NotificationService.syncReminders(for: savedStep)
        dismiss()
    }
}

#Preview {
    StepFormView(projectId: UUID())
        .modelContainer(for: TaskItem.self, inMemory: true)
}
