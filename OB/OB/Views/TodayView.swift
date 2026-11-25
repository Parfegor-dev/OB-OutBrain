//
//  TodayView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("План дня появится здесь")
                .foregroundStyle(.secondary)
                .navigationTitle("Сегодня")
        }
    }
}

#Preview {
    TodayView()
}
