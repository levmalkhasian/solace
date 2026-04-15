//
//  SettingsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI
import FamilyControls

struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 24, alignment: .center)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

}

struct SolaceFooter: View { // Footer struct
    var body: some View {
        Text("© 2026 Solace")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.bottom, 24)
    }
}

struct SettingsView: View {
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager
    @State private var showEmergencyConfirm = false
    @State private var showStartWithoutTagConfirm = false
    @State private var showStartWithoutTagError: String?
    @AppStorage("hideSensitiveContent") private var hideSensitiveContent = false
    @AppStorage("blockInAppPurchases") private var blockInAppPurchases = false
    @AppStorage("blockAppInstalls") private var blockAppInstalls = false
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
    @AppStorage("selectedFocusModeID") private var selectedFocusModeIDString: String = ""

    private func startFocusWithoutTag() {
        guard !vm.isFocused else { return }
        let modes = FocusModesPersistence.load()
        guard let id = UUID(uuidString: selectedFocusModeIDString),
              let mode = modes.first(where: { $0.id == id }) else {
            showStartWithoutTagError = "Pick a focus mode on the Home tab before starting."
            return
        }
        shieldManager.selection = mode.selection
        shieldManager.applyShield()
        vm.startFocus()
    }
    
    // SETTINGS TAB
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.top, 30)
                    .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    VStack(spacing: 12) {
                        SettingsButton(
                            title: "Login (Coming Soon)",
                            icon: "key",
                            color: .blue
                        ) {
                        }

                        SettingsButton(
                            title: "Start Without Tag",
                            icon: "bolt.badge.clock",
                            color: Color.orange.opacity(0.9)
                        ) {
                            guard !vm.isFocused else { return }
                            showStartWithoutTagConfirm = true
                        }
                        .disabled(vm.isFocused)
                        .opacity(vm.isFocused ? 0.5 : 1.0)
                        .confirmationDialog(
                            "Start without scanning your tag?",
                            isPresented: $showStartWithoutTagConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Start Focus", role: .destructive) {
                                startFocusWithoutTag()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("You'll still need your tag to end the session. Use this only if you can't scan right now.")
                        }
                        .alert(
                            "Can't Start",
                            isPresented: Binding(
                                get: { showStartWithoutTagError != nil },
                                set: { if !$0 { showStartWithoutTagError = nil } }
                            )
                        ) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(showStartWithoutTagError ?? "")
                        }

                        SettingsButton(
                            title: "Emergency Unblock",
                            icon: "exclamationmark.triangle",
                            color: .red
                        ) {
                            showEmergencyConfirm = true
                        }
                        .confirmationDialog(
                            vm.isFocused ? "Use an emergency unblock? You have \(shieldManager.emergencyUnblocksRemaining) left." : "You are not in focus mode currently.",
                            isPresented: $showEmergencyConfirm,
                            titleVisibility: .visible
                        ) {
                            if vm.isFocused {
                                Button("Unblock", role: .destructive) {
                                    let didUnblock = shieldManager.emergencyUnblock()
                                    if didUnblock {
                                        vm.endFocus()
                                    } else {
                                        print("You’ve used all 3 emergency unblocks.")
                                    }
                                }

                                Button("Cancel", role: .cancel) {
                                }
                            } else {
                                Button("OK", role: .cancel) {
                                }
                            }
                        }
                        SettingsButton(
                            title: "Contact Us!",
                            icon: "envelope",
                            color: .gray
                        ) {
                            if let url = URL(string: "mailto:support@solaceapp.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    VStack(spacing: 16) {
                        Toggle(isOn: $hideSensitiveContent) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hide Sensitive Content")
                                    .font(.headline)
                                Text("Block adult websites and explicit music, podcasts, and news during focus sessions.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .disabled(vm.isFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )

                        Toggle(isOn: $blockInAppPurchases) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Block In-App Purchases")
                                    .font(.headline)
                                Text("Prevent purchases from being made inside apps during focus sessions.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .disabled(vm.isFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )

                        Toggle(isOn: $blockAppInstalls) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Block App Installs")
                                    .font(.headline)
                                Text("Prevent new apps from being downloaded from the App Store during focus sessions.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .disabled(vm.isFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )

                        if vm.isFocused {
                            Text("Privacy settings are locked while a focus session is active.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // DEBUG — temporary until ship. Lets you re-trigger the
                // onboarding flow without deleting the app.
                VStack(alignment: .leading, spacing: 12) {
                    Text("Debug")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    SettingsButton(
                        title: "Replay Onboarding",
                        icon: "arrow.counterclockwise",
                        color: Color.purple.opacity(0.8)
                    ) {
                        onboardingComplete = false
                    }
                }
            }
                .padding(.horizontal, 24)

                SolaceFooter()
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .foregroundColor(.white)
    }
}
