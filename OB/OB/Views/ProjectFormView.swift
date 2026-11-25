//
//  ProjectFormView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct ProjectFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var nextStep = ""
    @State private var status: ProjectStatus = .active
    @State private var contextNotes = ""
    @State private var reminders: [Reminder] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $title)
                }
                Section {
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
                Section {
                    TextField("Следующий шаг", text: $nextStep)
                    Picker("Статус", selection: $status) {
                        Text("Активен").tag(ProjectStatus.active)
                        Text("Пауза").tag(ProjectStatus.paused)
                        Text("Завершён").tag(ProjectStatus.done)
                    }
                }
                Section("Заметки") {
                    TextEditor(text: $contextNotes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Новый проект")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .onChange(of: hasDeadline) { recomputeReminders() }
            .onChange(of: deadline) { recomputeReminders() }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNextStep: String {
        nextStep.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func recomputeReminders() {
        reminders = Reminder.recomputed(current: reminders, deadline: hasDeadline ? deadline : nil)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        let project = Project(
            title: trimmedTitle,
            deadline: hasDeadline ? deadline : nil,
            status: status,
            nextStep: trimmedNextStep.isEmpty ? nil : trimmedNextStep,
            contextNotes: contextNotes,
            reminders: reminders
        )
        modelContext.insert(project)
        try? modelContext.save()
        NotificationService.syncReminders(for: project)
        dismiss()
    }
}

#Preview {
    ProjectFormView()
        .modelContainer(for: Project.self, inMemory: true)
}
