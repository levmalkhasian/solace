//
//  HomeView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/27/25.
//

import SwiftUI

struct HomeView: View {
    // Inject shared instances from ContentView
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager
    @Binding var focusModes: [FocusMode] // Saved Modes
    let nfcManager: NFCManager

    // Control the system FamilyActivityPicker from the parent
    @Binding var showingPicker: Bool

    // Local UI state for this tab
    @State private var showingModesSheet = false
    @Binding var selectedFocusModeID: UUID? // User-chosen focus mode in sheet
    let currentModeName: String
    
    // HOME TAB
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text("Solace")
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Spacer(minLength: 20)

                VStack {
                    
                Image(systemName: vm.isFocused ? "lock.shield.fill": "lock.shield")
                    .foregroundColor(vm.isFocused ? .red :.blue)
                    .animation(Animation.easeInOut(duration: 0.3), value: vm.isFocused)
                    .font(.system(size: 180))
                    .aspectRatio(contentMode: .fit)
                
                if !vm.isFocused {
                    // Start Focus Button
                    Button {
                        guard let id = selectedFocusModeID,
                              let mode = focusModes.first(where: { $0.id == id }) else {
                            print("Select a focus mode first")
                            return
                        }
                        
                        // Load the mode's selection into ShieldManager BEFORE scanning
                        shieldManager.selection = mode.selection
                        
                        nfcManager.startScan(prompt: "Scan to Start Focus") { success in
                            if success {
                                shieldManager.applyShield()
                                vm.startFocus()
                            } else {
                                print("Failed to start focus mode.")
                            }
                        }
                    } label: {
                        Text("Start Focus")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .disabled(selectedFocusModeID == nil)

                    Button {
                        showingModesSheet = true
                    } label: {
                        Text("Manage Focus Modes")
                            .foregroundColor(.blue)
                            .font(.headline)
                            .padding(.top, 10)
                    }
                    Text(currentModeName == "None"
                         ? "Current Mode: None"
                         : "Current Mode: \(currentModeName)")
                    .padding(.bottom, 5)
                    .foregroundColor(currentModeName == "None" ? .gray : .green)
                    
                    Text("Today's Focus: \(vm.timeElapsedToday.asClock)")
                        //.font(.callout)
                        .foregroundColor(.gray)
                        .padding(.top, 1)
                    
                }
                
                // Focus UI (shows only while focused)
                if vm.isFocused {
                    FocusView(vm: vm, shieldManager: shieldManager, nfcManager: nfcManager)
                }
                
                }
                .sheet(isPresented: $showingModesSheet) {
                    FocusModesSheetView(focusModes: $focusModes, selectedFocusModeID: $selectedFocusModeID)
                        .presentationDetents([.fraction(0.75), .large])
                        .presentationDragIndicator(.visible)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
