//
//  StatsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI

// MARK: - Filter

enum StatsFilter: String, CaseIterable {
    case week     = "Week"
    case month    = "Month"
    case lifetime = "Lifetime"
}

// MARK: - Card Components

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
                .monospacedDigit()

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
    }
}

struct SmallStatsCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .textCase(.uppercase)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .monospacedDigit()

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
    }
}

// MARK: - StatsView

struct StatsView: View {
    @ObservedObject var vm: FocusSessionManager
    @State private var filter: StatsFilter = .week

    init(vm: FocusSessionManager) {
        self.vm = vm
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(
            red: 75/255, green: 111/255, blue: 221/255, alpha: 1
        )
        appearance.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .selected
        )
        appearance.setTitleTextAttributes(
            [.foregroundColor: UIColor.white], for: .normal
        )
    }

    private var periodSeconds: Int {
        switch filter {
        case .week:     return vm.focusSeconds(daysBack: 7)
        case .month:    return vm.focusSeconds(daysBack: 30)
        case .lifetime: return vm.lifetimeFocusSecondsLive
        }
    }

    private var periodDays: Int {
        switch filter {
        case .week:     return vm.focusDays(daysBack: 7)
        case .month:    return vm.focusDays(daysBack: 30)
        case .lifetime: return vm.lifetimeFocusDaysTotal
        }
    }

    private var avgPerDay: Int {
        switch filter {
        case .week:     return periodSeconds / 7
        case .month:    return periodSeconds / 30
        case .lifetime: return periodSeconds / max(vm.lifetimeFocusDaysTotal, 1)
        }
    }

    private var periodLabel: String {
        switch filter {
        case .week:     return "This week"
        case .month:    return "This month"
        case .lifetime: return "All time"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Stats")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.top, 30)
                    .padding(.bottom, 24)

                // Filter picker
                Picker("Filter", selection: $filter) {
                    ForEach(StatsFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // MARK: Period stats
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(periodLabel)

                    StatsCard(
                        title: "Focus Time",
                        value: periodSeconds.asClock,
                        subtitle: "Total focused time \(periodLabel.lowercased())"
                    )

                    HStack(spacing: 12) {
                        SmallStatsCard(title: "Days Focused", value: "\(periodDays) days")
                        SmallStatsCard(title: "Avg / Day",    value: avgPerDay.asShortClock)
                    }
                }
                .padding(.horizontal, 24)

                // MARK: Hours Saved
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Hours Saved")

                    if filter == .lifetime {
                        StatsCard(
                            title: "Time Reclaimed",
                            value: vm.lifetimeFocusSecondsLive.asHours,
                            subtitle: "Hours saved from distraction, all time"
                        )
                    } else {
                        StatsCard(
                            title: "Hours Saved",
                            value: periodSeconds.asHours,
                            subtitle: "Time reclaimed from distraction \(periodLabel.lowercased())"
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // MARK: Today
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Today")

                    HStack(spacing: 12) {
                        SmallStatsCard(title: "Today's Focus", value: vm.todayFocusSeconds.asClock)
                        SmallStatsCard(title: "Last Session",  value: vm.lastSessionTime.asClock)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)

                SolaceFooter()
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.solaceNavy)
        .foregroundColor(.white)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.gray)
            .textCase(.uppercase)
    }
}
