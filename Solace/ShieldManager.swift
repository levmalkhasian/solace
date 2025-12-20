//
//  ShieldManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI
import FamilyControls
import ManagedSettings

final class ShieldManager: ObservableObject {
    // Choosing apps to block function
    @Published var selection = FamilyActivitySelection() // The apps the user picked
    @Published var alwaysAllowed = FamilyActivitySelection() // Apps that are allowed always
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
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens // block apps
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
}
