//
//  TodayView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query private var plans: [DayPlan]

    @State private var showAddTask = false
    @State private var showEveningReview = false
    @State private var editingTask: TaskItem?

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

    private var planEntries: [PlanEntry] {
        guard let todayPlan else { return [] }
        return todayPlan.items.compactMap { item in
            guard let task = tasks.first(where: { $0.id == item.taskId }) else { return nil }
            return PlanEntry(item: item, task: task)
        }
    }

    private var activeEntries: [PlanEntry] {
        planEntries.filter { $0.task.status != .done }
    }

    private func byDeadline(_ lhs: PlanEntry, _ rhs: PlanEntry) -> Bool {
        (lhs.task.deadline ?? .distantFuture) < (rhs.task.deadline ?? .distantFuture)
    }

    private var focusEntries: [PlanEntry] {
        activeEntries.filter { $0.task.priority == .high }.sorted(by: byDeadline)
    }

    private var minorEntries: [PlanEntry] {
        activeEntries.filter { $0.task.priority != .high }.sorted(by: byDeadline)
    }

    private var doneCount: Int {
        tasks.filter { $0.status == .done }.count
    }

    private var unplannedTasks: [TaskItem] {
        let plannedIds = Set(todayPlan?.items.map(\.taskId) ?? [])
        return tasks
            .filter { !plannedIds.contains($0.id) && $0.status != .done && $0.status != .cancelled }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeEntries.isEmpty && unplannedTasks.isEmpty && doneCount == 0 {
                    ContentUnavailableView(
                        "День пуст",
                        systemImage: "sun.max",
                        description: Text("Добавь задачу — и собери план дня.")
                    )
                } else {
                    List {
                        if !focusEntries.isEmpty {
                            Section("Фокусы") {
                                ForEach(focusEntries) { entry in
                                    planRow(entry)
                                }
                            }
                        }
                        if !minorEntries.isEmpty {
                            Section("Мелочи") {
                                ForEach(minorEntries) { entry in
                                    planRow(entry)
                                }
                            }
                        }
                        if !unplannedTasks.isEmpty {
                            Section("Без плана") {
                                ForEach(unplannedTasks) { task in
                                    unplannedRow(task)
                                }
                            }
                        }
                        Section {
                            NavigationLink {
                                DoneTasksView()
                            } label: {
                                Label("Выполнено · \(doneCount)", systemImage: "checkmark.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Сегодня")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEveningReview = true
                    } label: {
                        Label("Вечерний итог", systemImage: "moon.stars")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTask = true
                    } label: {
                        Label("Новая задача", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEveningReview, onDismiss: refreshNextStepNudge) {
                EveningReviewView()
            }
            .sheet(isPresented: $showAddTask, onDismiss: refreshNextStepNudge) {
                TaskEditView()
            }
            .sheet(item: $editingTask, onDismiss: refreshNextStepNudge) { task in
                TaskEditView(task: task)
            }
        }
    }

    @ViewBuilder
    private func planRow(_ entry: PlanEntry) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleDone(entry.task)
            } label: {
                Image(systemName: entry.task.status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.task.status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.task.title)
                    .strikethrough(entry.task.status == .done)
                HStack(spacing: 8) {
                    if let deadline = entry.task.deadline {
                        Label(deadline.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    }
                    if let estimate = entry.task.estimateMin {
                        Label("\(estimate) мин", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = entry.task
        }
        .swipeActions(edge: .trailing) {
            Button {
                removeFromPlan(entry.task)
            } label: {
                Label("Убрать из плана", systemImage: "calendar.badge.minus")
            }
            .tint(.orange)
        }
    }

    @ViewBuilder
    private func unplannedRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                if let deadline = task.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                addToPlan(task)
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
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

    private func toggleDone(_ task: TaskItem) {
        if task.status == .done {
            task.status = .todo
            task.completedAt = nil
        } else {
            task.status = .done
            task.completedAt = Date()
        }
        try? modelContext.save()
        NotificationService.syncReminders(for: task)
        refreshNextStepNudge()
    }

    private func addToPlan(_ task: TaskItem) {
        let plan = DayPlan.today(in: modelContext)
        plan.items.append(PlanItem(taskId: task.id, timeBlock: nil, approved: true))
        try? modelContext.save()
        refreshNextStepNudge()
    }

    private func removeFromPlan(_ task: TaskItem) {
        todayPlan?.items.removeAll { $0.taskId == task.id }
        try? modelContext.save()
        refreshNextStepNudge()
    }

    private func deleteTask(_ task: TaskItem) {
        NotificationService.cancelReminders(ownerId: task.id)
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func refreshNextStepNudge() {
        let open = planEntries.filter { $0.task.status != .done }
        let next = open.first(where: { $0.task.priority == .high }) ?? open.first
        if let next {
            NotificationService.scheduleNextStep(title: next.task.title, estimateMin: next.task.estimateMin)
        } else {
            NotificationService.cancelNextStep()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [TaskItem.self, DayPlan.self], inMemory: true)
}
