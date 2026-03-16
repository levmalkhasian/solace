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
    @EnvironmentObject var vm: FocusSessionManager
    @StateObject private var shieldManager = ShieldManager()
    @State private var showingPicker = false
    @State private var focusModes: [FocusMode] = FocusModesPersistence.load()
    @AppStorage("selectedFocusModeID") private var selectedFocusModeIDString: String = ""

    private var selectedFocusModeID: Binding<UUID?> {
        Binding(
            get: { UUID(uuidString: selectedFocusModeIDString) },
            set: { selectedFocusModeIDString = $0?.uuidString ?? "" }
        )
    }
    private let nfcManager = NFCManager()
    
    private var currentModeName: String {
        // Get focus name for home screen
        guard let id = selectedFocusModeID.wrappedValue,
              let mode = focusModes.first(where: { $0.id == id }) else {
            return "None"
        }
        return mode.name
    }
    
    var body: some View {
        TabView {
            // HOME VIEW (MAIN)
            HomeView(
                vm: vm,
                shieldManager: shieldManager,
                focusModes: $focusModes,
                nfcManager: nfcManager,
                showingPicker: $showingPicker,
                selectedFocusModeID: selectedFocusModeID,
                currentModeName: currentModeName
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            // ALARM TAB - Linked to Separate File
            AlarmView(vm: vm)
                .tabItem{
                    Image(systemName: "alarm.fill")
                    Text("Alarm")
                }
            
            // STATS TAB - Linked to Separate File
            StatsView(vm: vm)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
            
            // SETTINGS TAB - Linked to Separate File
            SettingsView(vm: vm, shieldManager: shieldManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        
        .onChange(of: focusModes) { _, _ in
            FocusModesPersistence.save(focusModes)
        }
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        
        .familyActivityPicker(isPresented: $showingPicker,
                              selection: $shieldManager.selection)
        .task { await shieldManager.requestAuthentication() }
        
        
        //.fullScreenCover(isPresented: $vm.isFocused) {
        //    FocusView(
        //        vm: vm,
        //        shieldManager: shieldManager,
        //        nfcManager: nfcManager
        //    )
        //}
    }
}
#Preview {
    ContentView()
}
