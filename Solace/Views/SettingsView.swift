//
//  SettingsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var vm: FocusViewModel
    @ObservedObject var shieldManager: ShieldManager
    @State private var showEmergencyConfirm = false
    
    // SETTINGS TAB
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)

            Spacer()
            VStack {
                Text("Login")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                Text("Coming soon")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                Button {
                    // Step 1: ask for confirmation (no side effects here)
                    showEmergencyConfirm = true
                } label: {
                    Text("Emergency Unblock")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                }
                .confirmationDialog(
                    vm.isFocused ? "Use an emergency unblock? You have \(shieldManager.emergencyUnblocksRemaining) left.": "You are not in focus mode currently.",
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
                            // do nothing
                        }
                    } else {
                        Button("OK", role: .cancel) {
                            // do nothing
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}
