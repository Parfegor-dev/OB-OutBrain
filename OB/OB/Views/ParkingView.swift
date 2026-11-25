//
//  ParkingView.swift
//  OB
//
//  Created by Егор on 25.11.2026.
//

import SwiftUI

struct ParkingView: View {
    var body: some View {
        NavigationStack {
            Text("Идеи и «когда-нибудь» появятся здесь")
                .foregroundStyle(.secondary)
                .navigationTitle("Парковка")
        }
    }
}

#Preview {
    ParkingView()
}
