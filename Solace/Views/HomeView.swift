//
//  HomeView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import SwiftUI

struct HomeView: View {
    // Inject shared instances from ContentView
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager
    @Binding var focusModes: [FocusMode] // Saved Modes
    let nfcManager: NFCManager

    // Control the system FamilyActivityPicker from the parent
    @Binding var showingPicker: Bool

    // Local UI state for this tab
    @State private var showingModesSheet = false
    @Binding var selectedFocusModeID: UUID? // User-chosen focus mode in sheet
    let currentModeName: String
    
    // HOME TAB
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text("Solace")
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Spacer(minLength: 20)

                VStack(spacing: 24) {

                    // HERO CARD
                    VStack(spacing: 16) {
                        Image(systemName: vm.isFocused ? "lock.shield.fill" : "lock.shield")
                            .foregroundColor(vm.isFocused ? .red : .blue)
                            .animation(.easeInOut(duration: 0.3), value: vm.isFocused)
                            .font(.system(size: 120))

                        Text(vm.isFocused ? "Focus Active" : "Ready to Focus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(vm.isFocused
                             ? "Your distractions are currently blocked."
                             : "Select a focus mode and scan your tag to begin.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )

                    // PRIMARY ACTION
                    if !vm.isFocused {
                        Button {
                            guard let id = selectedFocusModeID,
                                  let mode = focusModes.first(where: { $0.id == id }) else {
                                print("Select a focus mode first")
                                return
                            }

                            shieldManager.selection = mode.selection

                            nfcManager.startScan(prompt: "Scan to Start Focus") { success in
                                if success {
                                    shieldManager.applyShield()
                                    vm.startFocus()
                                } else {
                                    print("Failed to start focus mode.")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Start Focus")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(selectedFocusModeID == nil)
                    } else {
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

                    // MODE CARD
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Mode")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        HStack {
                            Text(currentModeName == "None" ? "No mode selected" : currentModeName)
                                .font(.headline)
                                .foregroundColor(currentModeName == "None" ? Color.white.opacity(0.65) : .green)

                            Spacer()

                            Button {
                                guard !vm.isFocused else { return }
                                showingModesSheet = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                    Text("Manage")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundColor(vm.isFocused ? .gray : .blue)
                                .padding(.horizontal, 10)
                                .frame(height: 30)
                                .background(
                                    Capsule()
                                        .fill((vm.isFocused ? Color.gray : Color.blue).opacity(0.16))
                                )
                            }
                            .disabled(vm.isFocused)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )

                    // SESSION STATS
                    VStack(alignment: .leading, spacing: 14) {
                        if vm.isFocused {
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .center, spacing: 10) {
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
                                .frame(maxWidth: .infinity, alignment: .center)

                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 1, height: 58)

                                VStack(alignment: .center, spacing: 10) {
                                    Text("Today's Focus")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)

                                    Text((vm.timeElapsedToday + vm.timeElapsed).asClock)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                }
                .padding(.horizontal, 24)
                .sheet(isPresented: $showingModesSheet) {
                    FocusModesSheetView(focusModes: $focusModes, selectedFocusModeID: $selectedFocusModeID)
                        .presentationDetents([.fraction(0.75), .large])
                        .presentationDragIndicator(.visible)
                }

                Spacer(minLength: 0)

                SolaceFooter()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
