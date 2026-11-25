//
//  RemindersView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI

struct RemindersView: View {
    @Binding var reminders: [Reminder]
    let parentTitle: String
    let deadline: Date

    @State private var showAdd = false
    @State private var editing: Reminder?

    private var sorted: [Reminder] {
        reminders.sorted { $0.fireAt < $1.fireAt }
    }

    private var displayTitle: String {
        let trimmed = parentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Без названия" : trimmed
    }

    var body: some View {
        List {
            if reminders.isEmpty {
                Text("Нет напоминаний")
                    .foregroundStyle(.secondary)
            }
            ForEach(sorted) { reminder in
                Button {
                    editing = reminder
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(displayTitle) — \(Reminder.offsetText(fireAt: reminder.fireAt, deadline: deadline))")
                            Text(reminder.fireAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if reminder.isAuto {
                            Text("авто")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Напоминания")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Label("Добавить напоминание", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ReminderEditView(reminder: nil) { date in
                reminders.append(Reminder(fireAt: date, isAuto: false))
            }
        }
        .sheet(item: $editing) { reminder in
            ReminderEditView(reminder: reminder) { date in
                if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                    reminders[index].fireAt = date
                    reminders[index].isAuto = false
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let target = sorted[index]
            reminders.removeAll { $0.id == target.id }
        }
    }
}

struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Date) -> Void

    @State private var fireAt: Date

    init(reminder: Reminder?, onSave: @escaping (Date) -> Void) {
        self.onSave = onSave
        _fireAt = State(initialValue: reminder?.fireAt ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Дата и время", selection: $fireAt, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Напоминание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(fireAt)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RemindersView(
            reminders: .constant([
                Reminder(fireAt: Date().addingTimeInterval(3600), isAuto: true),
                Reminder(fireAt: Date().addingTimeInterval(7200), isAuto: false),
            ]),
            parentTitle: "Подтвердить хореографа",
            deadline: Date().addingTimeInterval(3 * 24 * 3600)
        )
    }
}
