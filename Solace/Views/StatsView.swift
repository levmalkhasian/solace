//
//  StatsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct StatsView: View {
    @ObservedObject var vm: FocusSessionManager

    // STATS TAB
    var body: some View {
        VStack(spacing: 0) {
            Text("Stats")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                VStack(spacing: 16) {
                    StatsCard(
                        title: "Today's Focus",
                        value: vm.timeElapsedToday.asClock,
                        subtitle: "Focused time logged today"
                    )

                    StatsCard(
                        title: "Last Session",
                        value: vm.lastSessionTime.asClock,
                        subtitle: "Length of your most recent focus session"
                    )

                    StatsCard(
                        title: "This Week",
                        value: vm.lastSessionTime.asClock,
                        subtitle: "Replace with total weekly time when available"
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            SolaceFooter()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .foregroundColor(.white)
    }
}
