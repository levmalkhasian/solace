//
//  DismissAlarmIntent.swift
//  Solace
//
//  Custom stop intent for the Solace wake alarm. Replaces AlarmKit's default
//  stop behavior: instead of stopping the alarm, it stores the alarm ID in a
//  UserDefaults bridge and opens the app. The app then presents the NFC scan
//  view, which is the only way to actually call AlarmManager.shared.stop.
//

import AlarmKit
import AppIntents
import Foundation

@available(iOS 26.0, *)
struct DismissAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Dismiss Alarm"
    static var description: IntentDescription = "Opens Solace to scan your tag and dismiss the alarm."
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() { self.alarmID = "" }

    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: alarmID) {
            AlarmDismissBridge.pendingID = uuid
        }
        // Intentionally do NOT call AlarmManager.shared.stop here.
        // The alarm keeps ringing until AlarmDismissView completes a scan.
        return .result()
    }
}
