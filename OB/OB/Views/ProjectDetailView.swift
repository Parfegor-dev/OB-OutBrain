//
//  ProjectDetailView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let project: Project

    @State private var title: String
    @State private var status: ProjectStatus
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var nextStep: String
    @State private var contextNotes: String
    @State private var reminders: [Reminder]

    @Query private var steps: [TaskItem]

    @State private var showAddStep = false
    @State private var editingStep: TaskItem?

    init(project: Project) {
        self.project = project
        _title = State(initialValue: project.title)
        _status = State(initialValue: project.status)
        _hasDeadline = State(initialValue: project.deadline != nil)
        _deadline = State(initialValue: project.deadline ?? Date())
        _nextStep = State(initialValue: project.nextStep ?? "")
        _contextNotes = State(initialValue: project.contextNotes)
        _reminders = State(initialValue: project.reminders)
        let projectId = project.id
        _steps = Query(filter: #Predicate<TaskItem> { step in
            step.projectId == projectId
        })
    }

    private var sortedSteps: [TaskItem] {
        steps.sorted { lhs, rhs in
            if (lhs.status == .done) != (rhs.status == .done) {
                return lhs.status != .done
            }
            return (lhs.deadline ?? .distantFuture) < (rhs.deadline ?? .distantFuture)
        }
    }

    var body: some View {
        Form {
            Section("Проект") {
                TextField("Название", text: $title)
                Picker("Статус", selection: $status) {
                    Text("Активен").tag(ProjectStatus.active)
                    Text("Пауза").tag(ProjectStatus.paused)
                    Text("Завершён").tag(ProjectStatus.done)
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
                TextField("Следующий шаг", text: $nextStep)
            }
            Section("Заметки") {
                TextEditor(text: $contextNotes)
                    .frame(minHeight: 60)
            }
            Section {
                ForEach(sortedSteps) { step in
                    HStack(spacing: 12) {
                        Button {
                            toggleDone(step)
                        } label: {
                            Image(systemName: step.status == .done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(step.status == .done ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .strikethrough(step.status == .done)
                            if let deadline = step.deadline {
                                Text(deadline.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingStep = step
                    }
                }
                .onDelete(perform: deleteSteps)

                Button {
                    showAddStep = true
                } label: {
                    Label("Добавить шаг", systemImage: "plus")
                }
            } header: {
                Text("Шаги")
            }
        }
        .navigationTitle("Проект")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить", action: saveProject)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showAddStep) {
            StepFormView(projectId: project.id)
        }
        .sheet(item: $editingStep) { step in
            StepFormView(step: step)
        }
        .onChange(of: hasDeadline) { recomputeReminders() }
        .onChange(of: deadline) { recomputeReminders() }
    }

    private func recomputeReminders() {
        reminders = Reminder.recomputed(current: reminders, deadline: hasDeadline ? deadline : nil)
    }

    private func saveProject() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedNextStep = nextStep.trimmingCharacters(in: .whitespacesAndNewlines)
        project.title = trimmedTitle
        project.status = status
        project.deadline = hasDeadline ? deadline : nil
        project.nextStep = trimmedNextStep.isEmpty ? nil : trimmedNextStep
        project.contextNotes = contextNotes
        project.reminders = reminders
        try? modelContext.save()
        NotificationService.syncReminders(for: project)
    }

    private func toggleDone(_ step: TaskItem) {
        step.status = step.status == .done ? .todo : .done
        try? modelContext.save()
        NotificationService.syncReminders(for: step)
    }

    private func deleteSteps(at offsets: IndexSet) {
        for index in offsets {
            let step = sortedSteps[index]
            NotificationService.cancelReminders(ownerId: step.id)
            modelContext.delete(step)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(title: "Клип", deadline: Date(), nextStep: "Написать Соне"))
    }
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
}
