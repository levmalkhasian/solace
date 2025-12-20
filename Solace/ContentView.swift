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
            
            Color.black.ignoresSafeArea()
            
            TabView {
                
                VStack {
                    VStack {
                        Text("Solace")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 30)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: vm.isFocused ? "lock.shield.fill": "lock.shield")
                            .foregroundColor(vm.isFocused ? .red :.blue)
                            .animation(Animation.easeInOut(duration: 0.3), value: vm.isFocused)
                            .font(.system(size: 180))
                            .aspectRatio(contentMode: .fit)
                        
                        if !vm.isFocused {
                            // Start Focus Button
                            Button {
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
                            Text("Today's Focus: \(vm.timeElapsedToday.asClock)")
                                .font(.callout)
                                .foregroundColor(.gray)
                                .padding(.top, 10)

                            Button {
                                showingPicker = true
                            } label: {
                                Text("Choose Apps to Block")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                        }
                        
                        // Focus UI (shows only while focused)
                        if vm.isFocused {
                            FocusView(vm: vm, shieldManager: shieldManager, nfcManager: nfcManager)
                        }
                        
                        
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                
                // HOME TAB
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
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
            .toolbarBackground(Color.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
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
