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
        VStack(spacing: 8) {
            Image("solace_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .opacity(0.8)

            Text("© 2026 Solace")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 24)
    }
}

struct SettingsView: View {
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager
    @State private var showEmergencyConfirm = false
    @AppStorage("hideSensitiveContent") private var hideSensitiveContent = false
    @AppStorage("blockInAppPurchases") private var blockInAppPurchases = false
    
    // SETTINGS TAB
    var body: some View {
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
                            title: "Login",
                            icon: "key",
                            color: .blue
                        ) {
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

                        if vm.isFocused {
                            Text("Privacy settings are locked while a focus session is active.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
