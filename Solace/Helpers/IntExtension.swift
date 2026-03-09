//
//  IntExtension.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

extension Int {
    var asClock: String {
        // Helper function to format seconds
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}
