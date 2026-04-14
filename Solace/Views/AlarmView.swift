//
//  AlarmView.swift
//  Solace
//
//  Wake-time configuration for the NFC-gated alarm. iOS 26+ only.
//

import SwiftUI

@available(iOS 26.0, *)
struct AlarmView: View {
    @ObservedObject var vm: FocusSessionManager
    @StateObject private var scheduler = AlarmScheduler()
    @State private var pickedTime: Date = Date()
    @State private var saving = false
    @State private var permissionDenied = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Alarm")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 12) {
                Text("Wake System")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                VStack(spacing: 16) {
                    // Time picker card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wake Time")
                            .font(.headline)
                        DatePicker(
                            "",
                            selection: $pickedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )

                    // Enable toggle card
                    Toggle(isOn: Binding(
                        get: { scheduler.isEnabled },
                        set: { newValue in
                            Task { await toggle(newValue) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Alarm")
                                .font(.headline)
                            Text("Ring at \(formatted(pickedTime)) every day. Only your NFC tag can dismiss it.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .disabled(saving)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )

                    // Status card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        Text(scheduler.isEnabled ? "Armed · \(formatted(pickedTime))" : "Disarmed")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            SolaceFooter()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .foregroundColor(.white)
        .onAppear {
            var comps = DateComponents()
            comps.hour = scheduler.wakeHour
            comps.minute = scheduler.wakeMinute
            pickedTime = Calendar.current.date(from: comps) ?? Date()
        }
        .onChange(of: pickedTime) { _, newValue in
            scheduler.setWakeTime(newValue)
            // If the alarm is already armed, re-schedule at the new time.
            if scheduler.isEnabled {
                Task { _ = await scheduler.enable() }
            }
        }
        .alert("Alarm Permission Needed", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable alarm access for Solace in Settings to use the wake feature.")
        }
    }

    private func toggle(_ newValue: Bool) async {
        saving = true
        defer { saving = false }
        if newValue {
            let ok = await scheduler.enable()
            if !ok { permissionDenied = true }
        } else {
            scheduler.disable()
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
