//
//  FocusMode.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import Foundation
import FamilyControls

struct FocusMode: Identifiable, Codable, Equatable {
    // Stores Focus Modes specific to user selection.
    var id: UUID = UUID() // Specific generated UUID for each focus mode
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
            let data = try JSONEncoder().encode(modes) // create JSONEncoder object
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save focus modes:", error)          }
    }

    static func load() -> [FocusMode] {
        // if the guard is true, the code after will execute. If not, return empty array.
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([FocusMode].self, from: data)
            // Take this JSON data and convert it into an array of FocusMode objects
        } catch {
            print("Failed to load focus modes:", error)
            return []
        }
    }
}

// TODO: Instead of UserDefaults, make actual focusmode data in a JSON file. More scalable.
// UserDefaults for smaller settings, not structured data.
