//
//  AlarmScheduler.swift
//  Solace
//
//  Wraps AlarmKit for Solace's single-alarm NFC-gated wake-up model.
//  Entire feature is iOS 26+ (AlarmKit requirement).
//

import SwiftUI
import AlarmKit

// Metadata attached to the alarm. AlarmKit requires any AlarmMetadata type
// to be nonisolated + Sendable so it can cross actor boundaries.
nonisolated struct SolaceAlarmMetadata: AlarmMetadata {
    init() {}
}

// Key used by the dismiss intent and the app to coordinate the NFC-gated
// dismiss handoff. When the stop button is tapped, the intent writes the
// alarm UUID here and opens the app; the app observes the value and
// presents the full-screen scan view.
enum AlarmDismissBridge {
    static let pendingKey = "pendingAlarmDismissID"

    static var pendingID: UUID? {
        get {
            guard let s = UserDefaults.standard.string(forKey: pendingKey) else { return nil }
            return UUID(uuidString: s)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: pendingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: pendingKey)
            }
        }
    }
}

@available(iOS 26.0, *)
@MainActor
final class AlarmScheduler: ObservableObject {
    @AppStorage("wakeAlarmHour") private var storedHour: Int = 7
    @AppStorage("wakeAlarmMinute") private var storedMinute: Int = 0
    @AppStorage("wakeAlarmEnabled") var isEnabled: Bool = false
    @AppStorage("wakeAlarmID") private var storedAlarmID: String = ""
    @AppStorage("wakeAlarmSound") private var storedSoundRaw: String = AlarmSound.systemDefault.rawValue

    var selectedSound: AlarmSound {
        AlarmSound(rawValue: storedSoundRaw) ?? .systemDefault
    }

    func setSound(_ sound: AlarmSound) {
        storedSoundRaw = sound.rawValue
    }

    var wakeTime: Date {
        var comps = DateComponents()
        comps.hour = storedHour
        comps.minute = storedMinute
        return Calendar.current.date(from: comps) ?? Date()
    }

    var wakeHour: Int { storedHour }
    var wakeMinute: Int { storedMinute }

    func setWakeTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        storedHour = comps.hour ?? 7
        storedMinute = comps.minute ?? 0
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                return state == .authorized
            } catch {
                print("AlarmKit authorization error:", error)
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Schedule / Cancel

    func enable() async -> Bool {
        guard await requestAuthorization() else { return false }
        cancel() // clear any previous alarm

        let id = UUID()
        let allDays: [Locale.Weekday] = [
            .sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday
        ]
        let schedule = Alarm.Schedule.relative(.init(
            time: .init(hour: storedHour, minute: storedMinute),
            repeats: .weekly(allDays)
        ))

        // Stop-only alert. Omitting secondaryButton means no snooze UI.
        let stopButton = AlarmButton(
            text: "Dismiss",
            textColor: .white,
            systemImageName: "wave.3.right"
        )
        let alert = AlarmPresentation.Alert(
            title: "Wake Up",
            stopButton: stopButton
        )
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: SolaceAlarmMetadata(),
            tintColor: Color.red
        )

        // stopIntent hijacks the stop button: opens the app (via openAppWhenRun
        // on the intent itself) and does NOT call AlarmManager.shared.stop.
        // The alarm keeps ringing until AlarmDismissView completes an NFC scan.
        let configuration = AlarmManager.AlarmConfiguration(
            schedule: schedule,
            attributes: attributes,
            stopIntent: DismissAlarmIntent(alarmID: id.uuidString),
            sound: selectedSound.alertKitSound
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            storedAlarmID = id.uuidString
            isEnabled = true
            return true
        } catch {
            print("Failed to schedule Solace alarm:", error)
            return false
        }
    }

    func disable() {
        cancel()
        isEnabled = false
    }

    func cancel() {
        if let id = currentAlarmID {
            try? AlarmManager.shared.cancel(id: id)
        }
        storedAlarmID = ""
    }

    var currentAlarmID: UUID? {
        guard !storedAlarmID.isEmpty else { return nil }
        return UUID(uuidString: storedAlarmID)
    }

    // Called after a successful NFC scan in AlarmDismissView.
    func stopRinging() {
        if let id = currentAlarmID {
            try? AlarmManager.shared.stop(id: id)
        }
        AlarmDismissBridge.pendingID = nil
    }
}
