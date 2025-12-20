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

final class FocusViewModel: ObservableObject { // toggle button logic
    @Published var isFocused: Bool = false
    @Published var timeElapsed: Int = 0
    @Published var lastSessionTime: Int = 0
    @AppStorage("timeElapsedToday") var timeElapsedToday: Int = 0
    private var timer: Timer? // ? == may or may not exist
    
    // NFC
    @AppStorage("nfcTagID") var nfcTagID: String = "04A1B2C3D4E5F6"
    
    //    Valid = NDEF contains a known string, like:
    //        •    Text record: SOLACE_UNLOCK
    //        •    URL record: https://solace.app/unlock
    
    func startFocus() {
        isFocused = true // ENABLE FOCUS MODE
        lastSessionTime = timeElapsed // last session time, might not need
        timeElapsed = 0 // stopwatch/current time
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timeElapsed += 1
        }
        // start timer, store in variable
    }
    
    func endFocus() {
        timer?.invalidate() // TURN OFF TIMER
        timer = nil

        timeElapsedToday += timeElapsed // append curr session time to total today.
        lastSessionTime = timeElapsed

        isFocused = false // DISABLE FOCUS MODE
        timeElapsed = 0 // RESET TIMER
    }
    
}

final class NFCManager: NSObject, NFCNDEFReaderSessionDelegate {
   
    private var session: NFCNDEFReaderSession? // stores session
    private var onResult: ((Bool) -> Void)? // callback - success or not
    
    func startScan(prompt: String, onResult: @escaping (Bool) -> Void) {
        self.onResult = onResult
        
        guard NFCNDEFReaderSession.readingAvailable else {
            onResult(false)
            self.onResult = nil
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = prompt // text shown in NFC scan
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        session.alertMessage = "Successful Scan."
        onResult?(true)
        onResult = nil
        self.session = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) { // error/cancel function callback
        onResult?(false)
        onResult = nil
        self.session = nil
    }
    
}

extension Int {
    var asClock: String {
        // Helper function to format seconds
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 { // if focus > 0 hours:
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        else { // if focus < 0 hours:
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
}

struct FocusView: View { // Focus Mode View
    @ObservedObject var vm: FocusViewModel
    @ObservedObject var shieldManager: ShieldManager // pass in shieldManager
    let nfcManager: NFCManager

    
    var body: some View {
        VStack {
            Text("Focus Mode: ON")
            Text("This Session: \(vm.timeElapsed.asClock)")
            Text("Today: \(vm.timeElapsedToday.asClock)")
            Button {
                shieldManager.clearShield() // uncomment later
                nfcManager.startScan(prompt: "Scan to End Focus") { success in
                    if success {
                        vm.endFocus() // call function here
                    } else {
                        print("Scan failed.")
                    }
                }
            } label: {
                Text("End Focus")
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                        )
            }
        }
        
    }
}

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
                    shieldManager.applyShield() // uncomment later
                    nfcManager.startScan(prompt: "Scan to Start Focus") { success in
                        if success {
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
