//
//  CaptureView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todayCaptures: [Capture]

    @State private var text = ""
    @State private var showSavedConfirmation = false
    @FocusState private var inputFocused: Bool

    init() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        _todayCaptures = Query(filter: #Predicate<Capture> { capture in
            capture.createdAt >= startOfDay
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextEditor(text: $text)
                        .focused($inputFocused)
                        .frame(minHeight: 120)
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Выгрузи кашу из головы…")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }

                    Button(action: save) {
                        Text("Записать")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedText.isEmpty)

                    NavigationLink {
                        CaptureListView()
                    } label: {
                        Label("Записано сегодня: \(todayCaptures.count)", systemImage: "tray.full")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)

                    if showSavedConfirmation {
                        Text("Записано")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.always)
            .onTapGesture {
                inputFocused = false
            }
            .navigationTitle("Захват")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Скрыть") {
                        inputFocused = false
                    }
                }
            }
            .onAppear { inputFocused = true }
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedText.isEmpty else { return }
        modelContext.insert(Capture(rawText: trimmedText))
        try? modelContext.save()
        text = ""
        withAnimation { showSavedConfirmation = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showSavedConfirmation = false }
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: Capture.self, inMemory: true)
}
