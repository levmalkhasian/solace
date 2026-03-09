//
//  FocusView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

struct FocusView: View { // Focus Mode View
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager // Pass in shieldManager
    let nfcManager: NFCManager

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {

                // SESSION CARD
                VStack(alignment: .leading, spacing: 10) {
                    Text("Focus Session")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    Text("Focus Mode Active")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This Session")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)

                            Text(vm.timeElapsed.asClock)
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 58)

                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Today's Focus")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)

                            Text(vm.timeElapsedToday.asClock)
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )

                // END FOCUS BUTTON
                Button {
                    nfcManager.startScan(prompt: "Scan to End Focus Mode") { success in
                        if success {
                            Task { @MainActor in
                                shieldManager.clearShield()
                                vm.endFocus()
                            }
                        } else {
                            print("Scan failed. Please try again.")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Focus")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Spacer(minLength: 0)

            SolaceFooter()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .foregroundColor(.white)
    }
}
