//
//  FocusViewModel.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

@MainActor
final class FocusSessionManager: ObservableObject { // toggle button logic
    @Published var isFocused: Bool = false
    @Published var focusStart: Date?
    @Published var timeElapsed: Int = 0
    @Published var lastSessionTime: Int = 0
    @AppStorage("timeElapsedToday") var timeElapsedToday: Int = 0
    @AppStorage("timeElapsedTodayAnchor") private var timeElapsedTodayAnchor: Double = 0
    // @AppStorage("startOfDay") var startOfDay = Calendar.current.startOfDay(for: Date())
    // Prints something like: startOfDay raw: 2026-01-05 08:00:00 +0000
    // Figure out how to implement calendar days that separate each day's focus time from one another.
    private var timer: Timer? // ? == may or may not exist
    
    func refreshToday(now: Date = Date()) {
        // Refresh the current day for accuracy
        let startOfDay = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        if timeElapsedTodayAnchor != startOfDay {
                timeElapsedToday = 0
                timeElapsedTodayAnchor = startOfDay
            }
        //Calendar.current.isDate(date, inSameDayAs: startOfDay)
    }
    
    func startFocus() {
        refreshToday() // Get current day
        isFocused = true // ENABLE FOCUS MODE
        focusStart = Date()
        // lastSessionTime = timeElapsed // last session time, might not need
        timeElapsed = 0 // stopwatch/current time
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let start = self?.focusStart else { return }
                self?.timeElapsed = Int(Date().timeIntervalSince(start))
            }
        }
        // start timer, store in variable
    }
    
    func endFocus() {
        refreshToday() // Get current day
        timer?.invalidate() // TURN OFF TIMER
        timer = nil
        
        guard let start = focusStart else {
            // If we don't have a start time, just safely reset.
            isFocused = false
            timeElapsed = 0
            return
        }
        
        let sessionSeconds = Int(Date().timeIntervalSince(start)) // accurate even when app closed

        lastSessionTime = sessionSeconds
        timeElapsedToday += sessionSeconds // append curr session time to total today.
        
        focusStart = nil
        isFocused = false // DISABLE FOCUS MODE
        timeElapsed = 0 // RESET TIMER
    }
}

