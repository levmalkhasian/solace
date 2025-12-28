//
//  AlarmManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

// import SwiftUI
import AlarmKit

@available(iOS 26.0, *)
func requestAuthorization() async {
    // Request Authorization for Alarms Manually
    do {
        let manager = AlarmManager.shared
        let status = try await manager.requestAuthorization()
        
    } catch {
        print("Error requesting authorization: \(error)")
    }
}

//@available(iOS 26.0, *)
//func checkAuthorization() {
//    // Check authorization level for alarm
//    switch AlarmManager.shared.authorizationState {
//    case .notDetermined:
//        requestAuthorization()
//    case .authorized:
//        scheduleAlarm()
//    case .denied:
//        print("Not authorized to schedule alarms. Please allow access in Settings for full functionality.")
//
//    @unknown default:
//        <#fatalError()#>
//    }
//}

@available(iOS 26.0, *)
func scheduleAlarm() {
    // Scheduling an alarm
    let countdownDuration = Alarm.CountdownDuration(preAlert: (10 * 60), postAlert: (5 * 60))
}
