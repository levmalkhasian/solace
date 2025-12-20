//
//  ContentView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/16/25.
//

import SwiftUI // Everything UI-Related
import CoreNFC // NFC Module
import FamilyControls // Screen Time + App Picker Module
import ManagedSettings // Enforces OS-Level Blocking

struct ContentView: View {
    @StateObject private var vm = FocusViewModel()
    @StateObject private var shieldManager = ShieldManager()
    @State private var showingPicker = false
    private let nfcManager = NFCManager()
    
    var body: some View {
        
        ZStack {
            VStack { // lays out content on top of eachother like a stack
                
                // Main Logo
                Image(systemName: "apple.meditate")
                    //.symbolEffect(.breathe)
                    .foregroundColor(.blue)
                    .font(.system(size: 180))
                    .aspectRatio(contentMode: .fit)
                //.padding(.all)
                //.cornerRadius(15)
                
                // Start Focus Button
                Button {
                    nfcManager.startScan(prompt: "Scan to Start Focus") { success in
                        if success {
                            shieldManager.applyShield()
                            vm.startFocus() // call function here
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
                
                Text("Today's Focus: \(vm.timeElapsedToday.asClock)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)

//                Text("Last Session: \(vm.lastSessionTime) seconds")
//                    .font(.callout)
//                    .fontWeight(.medium)
//                    .foregroundColor(.gray)
                
                Button {
                    showingPicker = true
                } label: {
                    Text("Choose Apps to Block")
                        .foregroundColor(.blue)
                        .font(.headline)
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black, ignoresSafeAreaEdges: .all)
        .familyActivityPicker(isPresented: $showingPicker, selection: $shieldManager.selection) // when showingPicker is true, show the Apple app picker UI.
        .task { await shieldManager.requestAuthentication() } // chosen apps stored into shieldManager.selection
        .fullScreenCover(isPresented: $vm.isFocused) {
            FocusView(
                vm: vm,
                shieldManager: shieldManager,
                nfcManager: nfcManager
            ) // when we are in focus mode, change view
        }
    }
}

#Preview {
    ContentView()
}
