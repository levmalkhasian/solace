//
//  IntExtension.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

extension Int {
    var asClock: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // HH:MM without seconds — for avg/day display
    var asShortClock: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    // Decimal hours — e.g. "3.5h" or "47h" — for hours-saved display
    var asHours: String {
        let h = Double(self) / 3600.0
        if h >= 10 { return String(format: "%.0fh", h) }
        return String(format: "%.1fh", h)
    }
}
