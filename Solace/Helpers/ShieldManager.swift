//
//  ShieldManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
final class ShieldManager: ObservableObject {
    // Choosing apps to block function
    @Published var selection = FamilyActivitySelection() // The apps the user picked
    @Published var alwaysAllowed = FamilyActivitySelection() // Apps that are allowed always
    @AppStorage("unblockme") var emergencyUnblocksRemaining: Int = 5
    private let store = ManagedSettingsStore() // Var to control shielding
    
    func requestAuthentication() async { // Grant screen time auth
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual) // Ask user for screen time permissions
            // REQUIRED
            } catch {
                print("FamilyControls authorization failed:", error)
        }
    }
    
    func applyShield() { // Applies app blocks
        clearShield() // Remove any leftover shields from a previous session
        // Block apps, but never block anything in the Always Allowed list
        let blockedApps = selection.applicationTokens.subtracting(alwaysAllowed.applicationTokens)
        if !blockedApps.isEmpty {
            store.shield.applications = blockedApps
        } else {
            store.shield.applications = nil
        }
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens) // block specific categories
        }
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens // block web domains
        }
    }
    
    func clearShield() { // Removes all blocks
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    func emergencyUnblock() -> Bool { // Emergency unblock, only 3.
        guard emergencyUnblocksRemaining > 0 else {
            return false
        }
        clearShield()
        emergencyUnblocksRemaining -= 1
        return true
    }
}
