//
//  CaptureDetailView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct CaptureDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let capture: Capture

    @Query private var projects: [Project]

    @State private var text: String
    @State private var showTaskSheet = false
    @State private var showProjectPicker = false

    init(capture: Capture) {
        self.capture = capture
        _text = State(initialValue: capture.rawText)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var firstLine: String {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? trimmedText
    }

    private var textChanged: Bool {
        trimmedText != capture.rawText
    }

    private var activeProjects: [Project] {
        projects.filter { $0.status == .active }.sorted { $0.title < $1.title }
    }

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                if textChanged {
                    Button("Сохранить текст", action: saveText)
                        .disabled(trimmedText.isEmpty)
                }
            } header: {
                Text("Текст захвата")
            } footer: {
                Text(capture.createdAt.formatted(date: .abbreviated, time: .shortened) + (capture.processed ? " · разобран" : " · не разобран"))
            }
            Section("Разбор") {
                Button("В задачу") { showTaskSheet = true }
                Button("В парковку") { moveToParking() }
                Button("В шаг проекта") { showProjectPicker = true }
                Button("Удалить", role: .destructive) { deleteCapture() }
            }
            .disabled(trimmedText.isEmpty)
        }
        .navigationTitle("Захват")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTaskSheet) {
            TaskEditView(prefillTitle: firstLine, prefillNotes: trimmedText, onSaved: {
                applyEditsAndMarkProcessed()
                dismiss()
            })
        }
        .sheet(isPresented: $showProjectPicker) {
            NavigationStack {
                List(activeProjects) { project in
                    Button(project.title) {
                        moveToStep(project)
                    }
                }
                .navigationTitle("В шаг проекта")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private func saveText() {
        capture.rawText = trimmedText
        try? modelContext.save()
    }

    private func applyEditsAndMarkProcessed() {
        capture.rawText = trimmedText
        capture.processed = true
        try? modelContext.save()
    }

    private func moveToParking() {
        modelContext.insert(Idea(title: firstLine, notes: trimmedText))
        applyEditsAndMarkProcessed()
        dismiss()
    }

    private func moveToStep(_ project: Project) {
        modelContext.insert(TaskItem(title: firstLine, notes: trimmedText, projectId: project.id))
        applyEditsAndMarkProcessed()
        dismiss()
    }

    private func deleteCapture() {
        modelContext.delete(capture)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CaptureDetailView(capture: Capture(rawText: "Позвонить Соне насчёт хореографа\nи уточнить дату съёмки"))
    }
    .modelContainer(for: [Capture.self, Project.self], inMemory: true)
}
