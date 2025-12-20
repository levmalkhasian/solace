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
    @Published var selection = FamilyActivitySelection() // the apps the user picked
    private let store = ManagedSettingsStore() // var to control shielding
    func requestAuthentication() async { // grant screen time auth
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual) // ask user for screen time permissions
            // REQUIRED
            } catch {
                print("FamilyControls authorization failed:", error)
        }
    }
    func applyShield() { // applies app blocks
        store.shield.applications = selection.applicationTokens
    }
    func clearShield() { // removes all blocks
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
