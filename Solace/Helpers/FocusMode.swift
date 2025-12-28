//
//  FocusMode.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import Foundation
import FamilyControls

struct FocusMode: Identifiable, Codable {
    // Stores Focus Modes specific to user selection.
    var id: UUID = UUID()
    var name: String
    var selection: FamilyActivitySelection

    init(id: UUID = UUID(), name: String, selection: FamilyActivitySelection) {
        self.id = id
        self.name = name
        self.selection = selection
    }
}

// PERSISTENCE FEATURES FOR FOCUS MODES
enum FocusModesPersistence {
    private static let key = "focus_modes_v1"

    static func save(_ modes: [FocusMode]) {
        do {
            let data = try JSONEncoder().encode(modes)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save focus modes:", error)
        }
    }

    static func load() -> [FocusMode] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([FocusMode].self, from: data)
        } catch {
            print("Failed to load focus modes:", error)
            return []
        }
    }
}
