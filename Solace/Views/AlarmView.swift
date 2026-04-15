//
//  AlarmView.swift
//  Solace
//
//  Wake-time configuration for the NFC-gated alarm. iOS 26+ only.
//
//  The picker and sound menu are pending state — nothing hits AlarmKit
//  until the user taps Save. That prevents accidental re-schedules from
//  a stray swipe on the wheel picker.
//

import SwiftUI
import UIKit

@available(iOS 26.0, *)
struct AlarmView: View {
    @ObservedObject var vm: FocusSessionManager
    @StateObject private var scheduler = AlarmScheduler()
    @State private var pickedTime: Date = Date()
    @State private var pickedSound: AlarmSound = .systemDefault
    @State private var saving = false
    @State private var permissionDenied = false
    @State private var justSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Alarm")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.top, 30)
                    .padding(.bottom, 24)

                heroCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: scheduler.isEnabled)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Wake Time")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    VStack(spacing: 16) {
                        timePickerCard
                        soundPickerCard
                        saveButton
                        if scheduler.isEnabled {
                            disableButton
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 0.9).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: scheduler.isEnabled)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

                SolaceFooter()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.solaceNavy)
        .foregroundColor(.white)
        .onAppear(perform: loadFromScheduler)
        .alert("Alarm Permission Needed", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Solace needs Alarm access to schedule your wake-up. Enable it in Settings.")
        }
    }

    // MARK: - Derived state

    private var pickedHour: Int {
        Calendar.current.component(.hour, from: pickedTime)
    }

    private var pickedMinute: Int {
        Calendar.current.component(.minute, from: pickedTime)
    }

    private var hasPendingChanges: Bool {
        pickedHour != scheduler.wakeHour ||
        pickedMinute != scheduler.wakeMinute ||
        pickedSound != scheduler.selectedSound
    }

    private var saveButtonTitle: String {
        if saving { return "Saving…" }
        if justSaved { return "Saved" }
        if scheduler.isEnabled {
            return hasPendingChanges ? "Update Alarm" : "Alarm Set"
        } else {
            return "Set Alarm"
        }
    }

    private var saveButtonIcon: String {
        if justSaved { return "checkmark.circle.fill" }
        if scheduler.isEnabled && !hasPendingChanges { return "checkmark.circle" }
        return "alarm.fill"
    }

    private var saveButtonDisabled: Bool {
        saving || (scheduler.isEnabled && !hasPendingChanges)
    }

    // MARK: - Cards

    private var heroCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(scheduler.isEnabled ? .red : .gray)
                .symbolEffect(.pulse, options: .repeating, isActive: scheduler.isEnabled)
                .scaleEffect(scheduler.isEnabled ? 1.08 : 1.0)
                .contentTransition(.symbolEffect(.replace))

            Text(scheduler.isEnabled ? "Set to \(storedTimeString)" : "No Alarm Set")
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.opacity)

            Text(scheduler.isEnabled
                 ? "Only your NFC tag can stop it."
                 : "Pick a time and tap Set Alarm.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: scheduler.isEnabled
                            ? [Color.red.opacity(0.35), Color.red.opacity(0.08)]
                            : [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(scheduler.isEnabled ? Color.red.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var timePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Wake Time", systemImage: "clock.fill")
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
            .onChange(of: pickedTime) { _, _ in justSaved = false }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var soundPickerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: pickedSound.icon)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sound")
                    .font(.headline)
                Text(pickedSound.displayName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Menu {
                ForEach(AlarmSound.allCases) { sound in
                    Button {
                        pickedSound = sound
                        justSaved = false
                    } label: {
                        Label(sound.displayName, systemImage: sound.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Change")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: saveButtonIcon)
                    .font(.headline)
                Text(saveButtonTitle)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(saveButtonDisabled ? Color.gray.opacity(0.25) : Color.red)
            )
            .foregroundColor(.white)
        }
        .disabled(saveButtonDisabled)
    }

    private var disableButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                scheduler.disable()
                justSaved = false
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                Text("Disable Alarm")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
            )
            .foregroundColor(.red)
        }
    }

    // MARK: - Actions

    private func loadFromScheduler() {
        var comps = DateComponents()
        comps.hour = scheduler.wakeHour
        comps.minute = scheduler.wakeMinute
        pickedTime = Calendar.current.date(from: comps) ?? Date()
        pickedSound = scheduler.selectedSound
    }

    private func save() async {
        saving = true
        defer { saving = false }

        scheduler.setWakeTime(pickedTime)
        scheduler.setSound(pickedSound)

        let ok = await scheduler.enable()
        if ok {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                justSaved = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            permissionDenied = true
        }
    }

    // MARK: - Formatting

    private var storedTimeString: String {
        var comps = DateComponents()
        comps.hour = scheduler.wakeHour
        comps.minute = scheduler.wakeMinute
        guard let date = Calendar.current.date(from: comps) else { return "--:--" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
