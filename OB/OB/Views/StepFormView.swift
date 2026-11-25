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

    init(projectId: UUID? = nil, step: TaskItem? = nil) {
        self.projectId = projectId
        self.step = step
        _title = State(initialValue: step?.title ?? "")
        _hasDeadline = State(initialValue: step.map { $0.deadline != nil } ?? false)
        _deadline = State(initialValue: step?.deadline ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $title)
                Toggle("Дедлайн", isOn: $hasDeadline)
                if hasDeadline {
                    DatePicker("Дата", selection: $deadline, displayedComponents: .date)
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
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let step {
            step.title = trimmed
            step.deadline = hasDeadline ? deadline : nil
        } else {
            modelContext.insert(TaskItem(title: trimmed, projectId: projectId, deadline: hasDeadline ? deadline : nil))
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    StepFormView(projectId: UUID())
        .modelContainer(for: TaskItem.self, inMemory: true)
}
