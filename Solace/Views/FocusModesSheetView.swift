//
//  FocusModesSheetView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import SwiftUI

struct FocusModesSheetView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var showingCreate = false
  @Binding var focusModes: [FocusMode]
  @Binding var selectedFocusModeID: UUID?

  var body: some View {
    NavigationStack {
        List {
            ForEach(focusModes) { mode in
                Button {
                    selectedFocusModeID = mode.id
                    dismiss()
                } label: {
                    HStack {
                        Text(mode.name)
                        Spacer()
                        if selectedFocusModeID == mode.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                let deletedIDs = indexSet.map { focusModes[$0].id }
                focusModes.remove(atOffsets: indexSet)

                if let selected = selectedFocusModeID, deletedIDs.contains(selected) {
                    selectedFocusModeID = nil
                }            }
        }
        .navigationTitle("Focus Modes")
        
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
          }
          ToolbarItem(placement: .topBarTrailing) {
            EditButton()
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingCreate = true    
              // navigate to create mode view
            } label: {
                Image(systemName: "plus")
            }
          }
        }
        .sheet(isPresented: $showingCreate) {
            CreateFocusModeView(focusModes: $focusModes)
        }
    }
  }
}
