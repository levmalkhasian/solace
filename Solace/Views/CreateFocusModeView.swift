//
//  CreateFocusModeView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct CreateFocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var showingPicker = false
    @State private var selection: FamilyActivitySelection
    @Binding var focusModes: [FocusMode]
    private let editingID: UUID?

    /// Create a new focus mode (default) or edit an existing one.
    init(focusModes: Binding<[FocusMode]>, editing mode: FocusMode? = nil) {
        _focusModes = focusModes
        if let mode {
            _name = State(initialValue: mode.name)
            _selection = State(initialValue: mode.selection)
            editingID = mode.id
        } else {
            _name = State(initialValue: "")
            _selection = State(initialValue: FamilyActivitySelection())
            editingID = nil
        }
    }

    private var isEditing: Bool { editingID != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Ex. Deep Work", text: $name)
                }
                Button("Choose Apps to Block") {
                    showingPicker = true
                }
            }
            .navigationTitle(isEditing ? "Edit Focus Mode" : "New Focus Mode")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let editingID,
                           let index = focusModes.firstIndex(where: { $0.id == editingID }) {
                            focusModes[index].name = trimmedName
                            focusModes[index].selection = selection
                        } else {
                            let mode = FocusMode(name: trimmedName, selection: selection)
                            focusModes.append(mode)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
    }
}
