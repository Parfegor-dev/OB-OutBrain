//
//  CaptureListView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct CaptureListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]

    var body: some View {
        Group {
            if captures.isEmpty {
                ContentUnavailableView(
                    "Нет захватов",
                    systemImage: "tray",
                    description: Text("Записанные мысли появятся здесь.")
                )
            } else {
                List {
                    ForEach(captures) { capture in
                        NavigationLink {
                            CaptureDetailView(capture: capture)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                if !capture.processed {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(capture.rawText)
                                        .fontWeight(capture.processed ? .regular : .semibold)
                                        .lineLimit(3)
                                    Text(capture.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .foregroundStyle(capture.processed ? .secondary : .primary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Входящие")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(captures[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        CaptureListView()
    }
    .modelContainer(for: Capture.self, inMemory: true)
}
