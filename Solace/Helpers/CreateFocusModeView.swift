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
    @State private var name = ""
    @State private var showingPicker = false
    @State private var selection = FamilyActivitySelection()
    @Binding var focusModes: [FocusMode]

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
            .navigationTitle("New Focus Mode")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let mode = FocusMode(name: trimmedName, selection: selection)
                        focusModes.append(mode) // saves selected focus mode
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
        // Choose which apps to block picker above.
    }
}
