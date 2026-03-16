//
//  FocusSessionManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

// Sessions that cross midnight are split at day boundaries in endFocus().

@MainActor
final class FocusSessionManager: ObservableObject {
    @Published var isFocused: Bool = false
    @Published var focusStart: Date?
    @Published var timeElapsed: Int = 0
    @AppStorage("focusStartTimestamp") private var focusStartTimestamp: Double = 0
    @AppStorage("isFocusedPersisted") private var isFocusedPersisted: Bool = false
    @AppStorage("timeElapsedToday") var timeElapsedToday: Int = 0
    @AppStorage("timeElapsedTodayAnchor") private var timeElapsedTodayAnchor: Double = 0
    @AppStorage("lastSessionTime") var lastSessionTime: Int = 0
    @AppStorage("lifetimeFocusSeconds") var lifetimeFocusSeconds: Int = 0
    @AppStorage("lifetimeFocusDaysBeforeHistory") private var lifetimeFocusDaysBeforeHistory: Int = 0
    private var timer: Timer?

    // MARK: - Daily history persistence

    private func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func loadDailyHistory() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: "dailyFocusHistory"),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return dict
    }

    private func saveDailyHistory(_ history: [String: Int]) {
        // Prune entries older than 30 days, counting pruned days toward lifetime total
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date())!
        let cutoffKey = dateKey(for: cutoff)
        let prunedDays = history.filter { $0.key < cutoffKey && $0.value > 0 }.count
        lifetimeFocusDaysBeforeHistory += prunedDays
        let kept = history.filter { $0.key >= cutoffKey }

        if let data = try? JSONEncoder().encode(kept) {
            UserDefaults.standard.set(data, forKey: "dailyFocusHistory")
        }
    }

    // MARK: - Stats helpers

    /// Total focus seconds over the last `daysBack` days (including today).
    func focusSeconds(daysBack: Int) -> Int {
        let history = loadDailyHistory()
        let calendar = Calendar.current
        let now = Date()
        var total = timeElapsedToday
        for daysAgo in 1..<daysBack {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                total += history[dateKey(for: date)] ?? 0
            }
        }
        return total
    }

    /// Number of days with at least 1 second of focus over the last `daysBack` days.
    func focusDays(daysBack: Int) -> Int {
        let history = loadDailyHistory()
        let calendar = Calendar.current
        let now = Date()
        var count = timeElapsedToday > 0 ? 1 : 0
        for daysAgo in 1..<daysBack {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                if (history[dateKey(for: date)] ?? 0) > 0 { count += 1 }
            }
        }
        return count
    }

    /// Lifetime unique focus days (history window + pre-history counter + today if applicable).
    var lifetimeFocusDaysTotal: Int {
        lifetimeFocusDaysBeforeHistory + focusDays(daysBack: 30)
    }

    func restoreSessionIfNeeded() {
        guard isFocusedPersisted, focusStartTimestamp > 0, !isFocused else { return }
        let start = Date(timeIntervalSince1970: focusStartTimestamp)
        focusStart = start
        isFocused = true
        timeElapsed = Int(Date().timeIntervalSince(start))
        startTimer()
    }

    func refreshToday(now: Date = Date()) {
        let startOfDay = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        if timeElapsedTodayAnchor != startOfDay {
            // Save yesterday's total to history before resetting
            if timeElapsedToday > 0 {
                let yesterday = Date(timeIntervalSince1970: timeElapsedTodayAnchor)
                var history = loadDailyHistory()
                history[dateKey(for: yesterday)] = (history[dateKey(for: yesterday)] ?? 0) + timeElapsedToday
                saveDailyHistory(history)
            }
            timeElapsedToday = 0
            timeElapsedTodayAnchor = startOfDay
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let start = self?.focusStart else { return }
                self?.timeElapsed = Int(Date().timeIntervalSince(start))
            }
        }
    }
    
    func startFocus() { // Start new focus session
        guard !isFocused else { return }
        refreshToday() // Get current day
        isFocused = true // ENABLE FOCUS MODE
        let now = Date()
        focusStart = now
        focusStartTimestamp = now.timeIntervalSince1970
        isFocusedPersisted = true
        // lastSessionTime = timeElapsed // last session time, might not need
        timeElapsed = 0 // stopwatch/current time for curr session
        startTimer() // start timer, store in variable
    }
    
    func endFocus() {
        guard isFocused, let start = focusStart else {
            isFocused = false
            timeElapsed = 0
            return
        }
        timer?.invalidate()
        timer = nil

        let now = Date()
        lastSessionTime = Int(now.timeIntervalSince(start))
        lifetimeFocusSeconds += lastSessionTime

        // Walk midnight boundaries from start → now, attributing each segment to the correct day.
        let calendar = Calendar.current
        var history = loadDailyHistory()
        var segmentStart = start

        while true {
            let nextMidnight = calendar.date(
                byAdding: .day, value: 1,
                to: calendar.startOfDay(for: segmentStart)
            )!

            if nextMidnight >= now {
                // Final segment — belongs to today.
                let todayAnchor = calendar.startOfDay(for: now).timeIntervalSince1970
                if timeElapsedTodayAnchor != todayAnchor {
                    // The day rolled over while the session was running.
                    if timeElapsedToday > 0 {
                        let oldDay = Date(timeIntervalSince1970: timeElapsedTodayAnchor)
                        history[dateKey(for: oldDay)] = (history[dateKey(for: oldDay)] ?? 0) + timeElapsedToday
                    }
                    timeElapsedToday = 0
                    timeElapsedTodayAnchor = todayAnchor
                }
                timeElapsedToday += Int(now.timeIntervalSince(segmentStart))
                break
            } else {
                // Segment ends at midnight — save to that day's history entry.
                let key = dateKey(for: segmentStart)
                history[key] = (history[key] ?? 0) + Int(nextMidnight.timeIntervalSince(segmentStart))
                segmentStart = nextMidnight
            }
        }

        saveDailyHistory(history)
        focusStart = nil
        focusStartTimestamp = 0
        isFocusedPersisted = false
        isFocused = false
        timeElapsed = 0
    }
}

