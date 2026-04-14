//
//  AlarmSiren.swift
//  Solace
//
//  Owns the in-app alarm noise that keeps playing after the AlarmKit alert
//  is tapped away. The only way to silence this is a successful NFC scan in
//  AlarmDismissView. Uses AVAudioPlayer with a bundled file if available;
//  otherwise falls back to AudioServicesPlayAlertSound on a timer so the
//  feature works even before real audio assets are added to the project.
//

import AVFoundation
import AudioToolbox
import UIKit

@MainActor
final class AlarmSiren: ObservableObject {
    private var player: AVAudioPlayer?
    private var fallbackTimer: Timer?
    private var hapticTimer: Timer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)

    func start(sound: AlarmSound) {
        stop()
        configureSession()
        startHaptics()

        if let url = sound.bundleURL, let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.player = player
            return
        }

        startFallbackTone()
    }

    func stop() {
        player?.stop()
        player = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        do {
            // .playback overrides the ringer/silent switch so the alarm is
            // audible even when the phone is on silent.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AlarmSiren: audio session error:", error)
        }
    }

    private func startFallbackTone() {
        // SystemSoundID 1005 (Tri-tone) is consistently loud across devices.
        // We fire it every second so it "loops" even though system sounds
        // don't natively loop.
        let soundID: SystemSoundID = 1005
        AudioServicesPlayAlertSound(soundID)
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlayAlertSound(soundID)
        }
    }

    private func startHaptics() {
        hapticGenerator.prepare()
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.hapticGenerator.impactOccurred()
            }
        }
    }
}
