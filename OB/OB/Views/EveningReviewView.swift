//
//  EveningReviewView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct EveningReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    @Query private var plans: [DayPlan]

    init() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        _plans = Query(filter: #Predicate<DayPlan> { plan in
            plan.date == startOfDay
        })
    }

    private struct PlanEntry: Identifiable {
        let item: PlanItem
        let task: TaskItem
        var id: UUID { task.id }
    }

    private var todayPlan: DayPlan? { plans.first }

    private var entries: [PlanEntry] {
        guard let todayPlan else { return [] }
        return todayPlan.items.compactMap { item in
            guard let task = tasks.first(where: { $0.id == item.taskId }) else { return nil }
            return PlanEntry(item: item, task: task)
        }
    }

    private var doneEntries: [PlanEntry] {
        entries.filter { $0.task.status == .done }
    }

    private var pendingEntries: [PlanEntry] {
        entries.filter { $0.task.status != .done }
    }

    private var summaryText: String {
        let total = entries.count
        let done = doneEntries.count
        if total == 0 {
            return "План был пуст — день прошёл без списка."
        }
        if done == total {
            return "Сделано всё: \(done) из \(total). Отличный день."
        }
        return "Сделано \(done) из \(total) — норм."
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(summaryText)
                        .font(.headline)
                }
                if !pendingEntries.isEmpty {
                    Section {
                        ForEach(pendingEntries) { entry in
                            Text(entry.task.title)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        moveToTomorrow(entry.task)
                                    } label: {
                                        Label("На завтра", systemImage: "calendar.badge.plus")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        Text("Переезжает?")
                    } footer: {
                        Text("Свайп влево по задаче — перенести на завтра. Что не свайпнул — останется в списке.")
                    }
                }
                if !doneEntries.isEmpty {
                    Section("Сделано") {
                        ForEach(doneEntries) { entry in
                            Label(entry.task.title, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Вечерний итог")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func moveToTomorrow(_ task: TaskItem) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let plan = DayPlan.plan(for: tomorrow, in: modelContext)
        if !plan.items.contains(where: { $0.taskId == task.id }) {
            plan.items.append(PlanItem(taskId: task.id, timeBlock: nil, approved: true))
        }
        todayPlan?.items.removeAll { $0.taskId == task.id }
        try? modelContext.save()
    }
}

#Preview {
    EveningReviewView()
        .modelContainer(for: [TaskItem.self, DayPlan.self], inMemory: true)
}
