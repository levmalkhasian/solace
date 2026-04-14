//
//  AlarmDismissView.swift
//  Solace
//
//  Full-screen dismiss UI shown after the AlarmKit alert is tapped. The
//  AlarmKit sound stops the moment the user taps the Dismiss button, so
//  this view takes over audio via AlarmSiren and only releases it on a
//  successful NFC scan. The view cannot be closed any other way — even if
//  the user backgrounds/force-quits the app, the pending ID persists in
//  UserDefaults and this view re-appears on the next launch.
//

import SwiftUI

@available(iOS 26.0, *)
struct AlarmDismissView: View {
    @ObservedObject var scheduler: AlarmScheduler
    @StateObject private var siren = AlarmSiren()
    @State private var nfcManager = NFCManager()
    @State private var scanning = false
    @State private var failedLastScan = false
    @State private var pulse = false
    @Environment(\.scenePhase) private var scenePhase
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Pulsing red gradient backdrop so the screen feels alarming
            // even when the phone is on silent.
            RadialGradient(
                colors: [
                    Color.red.opacity(pulse ? 0.55 : 0.25),
                    Color.black
                ],
                center: .center,
                startRadius: 40,
                endRadius: 600
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 32) {
                Spacer()

                Text(currentTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)

                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 220, height: 220)
                        .scaleEffect(pulse ? 1.08 : 0.92)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 110, weight: .semibold))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: 10) {
                    Text("Scan Tag to Stop Alarm")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Only your Solace NFC tag will silence it.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if failedLastScan {
                        Text("Scan failed — try again.")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                Button(action: startScan) {
                    HStack(spacing: 10) {
                        Image(systemName: "wave.3.right")
                            .font(.headline)
                        Text(scanning ? "Scanning…" : "Scan Tag")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                    )
                    .foregroundColor(.red)
                }
                .disabled(scanning)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            pulse = true
            siren.start(sound: scheduler.selectedSound)
            startScan()
        }
        .onChange(of: scenePhase) { _, phase in
            // If the user backgrounds the app, audio keeps playing thanks
            // to the .playback session. If they foreground without having
            // scanned, make sure the siren is still running.
            if phase == .active {
                siren.start(sound: scheduler.selectedSound)
            }
        }
        .interactiveDismissDisabled(true)
    }

    private var currentTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: Date())
    }

    private func startScan() {
        guard !scanning else { return }
        scanning = true
        failedLastScan = false
        nfcManager.startScan(prompt: "Scan to Stop Alarm") { success in
            Task { @MainActor in
                scanning = false
                if success {
                    siren.stop()
                    scheduler.stopRinging()
                    onDismiss()
                } else {
                    failedLastScan = true
                }
            }
        }
    }
}
