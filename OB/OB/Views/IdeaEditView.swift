//
//  IdeaEditView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct IdeaEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let idea: Idea

    @State private var title: String
    @State private var notes: String

    init(idea: Idea) {
        self.idea = idea
        _title = State(initialValue: idea.title)
        _notes = State(initialValue: idea.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $title)
                }
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Идея")
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
        idea.title = trimmed
        idea.notes = notes
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    IdeaEditView(idea: Idea(title: "Клип на крыше"))
        .modelContainer(for: Idea.self, inMemory: true)
}
