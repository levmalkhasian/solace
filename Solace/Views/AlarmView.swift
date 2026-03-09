//
//  AlarmView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI
import AlarmKit

struct AlarmView: View {
    @ObservedObject var vm: FocusSessionManager
    @State private var isAlarmEnabled = false
    var lastWakeTime: String?
    
    // ALARM TAB
    var body: some View {
        VStack(spacing: 0) {
            Text("Alarm")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 12) {
                Text("Wake System")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                VStack(spacing: 16) {
                    Toggle(isOn: $isAlarmEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Alarm")
                                .font(.headline)

                            Text("Turn on your NFC‑based wake alarm.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        Text(isAlarmEnabled ? "Alarm Enabled" : "Alarm Disabled")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Wake")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        Text(lastWakeTime ?? "No wake data yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
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
