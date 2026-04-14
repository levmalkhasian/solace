//
//  AlarmDismissView.swift
//  Solace
//
//  Full-screen dismiss UI shown after the alarm's Dismiss button opens the
//  app. Auto-starts an NFC scan; only a successful scan will call
//  AlarmManager.shared.stop and close this view.
//

import SwiftUI

@available(iOS 26.0, *)
struct AlarmDismissView: View {
    @ObservedObject var scheduler: AlarmScheduler
    @State private var nfcManager = NFCManager()
    @State private var scanning = false
    @State private var failedLastScan = false
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "wave.3.right")
                    .font(.system(size: 120))
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(spacing: 8) {
                    Text("Scan to Dismiss")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Tap your Solace tag to stop the alarm.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if failedLastScan {
                    Text("Scan failed. Try again.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                Spacer()

                Button {
                    startScan()
                } label: {
                    HStack {
                        Image(systemName: "wave.3.right")
                        Text(scanning ? "Scanning…" : "Scan Tag")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red)
                    )
                    .foregroundColor(.white)
                }
                .disabled(scanning)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: startScan)
        .interactiveDismissDisabled(true)
    }

    private func startScan() {
        guard !scanning else { return }
        scanning = true
        failedLastScan = false
        nfcManager.startScan(prompt: "Scan to Dismiss Alarm") { success in
            Task { @MainActor in
                scanning = false
                if success {
                    scheduler.stopRinging()
                    onDismiss()
                } else {
                    failedLastScan = true
                }
            }
        }
    }
}
