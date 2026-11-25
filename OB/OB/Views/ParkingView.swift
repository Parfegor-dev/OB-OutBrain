//
//  ParkingView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct ParkingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]

    @State private var showAddAlert = false
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            Group {
                if ideas.isEmpty {
                    ContentUnavailableView(
                        "Парковка пуста",
                        systemImage: "parkingsign",
                        description: Text("Идеи и «когда-нибудь» — сюда, чтобы голова отпускала.")
                    )
                } else {
                    List {
                        ForEach(ideas) { idea in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(idea.title)
                                    if idea.status == .ready {
                                        Text("созрела")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                                Text(idea.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    idea.status = idea.status == .ready ? .parked : .ready
                                } label: {
                                    Label(
                                        idea.status == .ready ? "В парковку" : "Созрела",
                                        systemImage: idea.status == .ready ? "arrow.uturn.left" : "checkmark"
                                    )
                                }
                                .tint(.green)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Парковка")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddAlert = true
                    } label: {
                        Label("Добавить идею", systemImage: "plus")
                    }
                }
            }
            .alert("Новая идея", isPresented: $showAddAlert) {
                TextField("Название", text: $newTitle)
                Button("Добавить", action: add)
                Button("Отмена", role: .cancel) { newTitle = "" }
            }
        }
    }

    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(Idea(title: trimmed))
        newTitle = ""
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(ideas[index])
        }
    }
}

#Preview {
    ParkingView()
        .modelContainer(for: Idea.self, inMemory: true)
}
