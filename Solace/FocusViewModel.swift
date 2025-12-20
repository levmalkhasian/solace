//
//  FocusViewModel.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

final class FocusViewModel: ObservableObject { // toggle button logic
    @Published var isFocused: Bool = false
    @Published var timeElapsed: Int = 0
    @Published var lastSessionTime: Int = 0
    @AppStorage("timeElapsedToday") var timeElapsedToday: Int = 0
    private var timer: Timer? // ? == may or may not exist
    
    // NFC
    //@AppStorage("nfcTagID") var nfcTagID: String = "04A1B2C3D4E5F6"
    
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
