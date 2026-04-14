//
//  OnboardingView.swift
//  Solace
//
//  First-launch branded onboarding. Walks the user through the concept,
//  the NFC tag purchase, and the required OS permissions. Sets
//  `onboardingComplete = true` when the user finishes, which gates the
//  main TabView in SolaceApp.
//

import SwiftUI
import FamilyControls
import CoreNFC
#if canImport(AlarmKit)
import AlarmKit
#endif

struct OnboardingView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
    @State private var step: Int = 0
    @StateObject private var permissionState = PermissionState()

    private let totalSteps = 5

    var body: some View {
        ZStack {
            // Branded gradient backdrop — deep navy → indigo → black.
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.18),
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft radial glow behind content.
            RadialGradient(
                colors: [
                    Color(red: 0.20, green: 0.40, blue: 0.95).opacity(0.30),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ZStack {
                    switch step {
                    case 0: welcomeStep
                    case 1: howItWorksStep
                    case 2: tagStep
                    case 3: permissionsStep
                    default: finishStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)

                footerButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .foregroundColor(.white)
        .task { await permissionState.refresh() }
    }

    // MARK: - Progress

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.white : Color.white.opacity(0.15))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Image("solace_mark")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .shadow(color: Color.blue.opacity(0.4), radius: 30, x: 0, y: 12)

            VStack(spacing: 12) {
//                Image("solace_logo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 42)

                Text("Let's get started on getting your life back.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var howItWorksStep: some View {
        VStack(spacing: 24) {
            Spacer()

            stepHeader(
                icon: "lock.shield.fill",
                title: "How Solace Works",
                subtitle: "Physical friction beats willpower."
            )

            VStack(alignment: .leading, spacing: 18) {
                featureRow(
                    icon: "hand.tap.fill",
                    title: "Start a focus session",
                    body: "Choose which apps and websites to block."
                )
                featureRow(
                    icon: "lock.fill",
                    title: "Stay locked in",
                    body: "Your distractions are blocked at the OS level."
                )
                featureRow(
                    icon: "wave.3.right",
                    title: "Only your tag can end it",
                    body: "Scan your NFC tag to unlock. No shortcuts."
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var tagStep: some View {
        VStack(spacing: 24) {
            Spacer()

            stepHeader(
                icon: "sensor.tag.radiowaves.forward.fill",
                title: "Get Your Solace Tag",
                subtitle: "A physical key to your focus."
            )

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)

                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Color.blue.opacity(0.4), radius: 24, x: 0, y: 12)

                VStack(spacing: 6) {
                    Text("Solace Focus Tag")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Waterproof · Keychain-ready · One-time purchase")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                Button {
                    if let url = URL(string: "https://solaceapp.com/tag") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Buy a Tag")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
                }

                Text("Already have an NFC tag? Any NDEF-compatible tag will work.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Spacer()

            stepHeader(
                icon: "checkmark.shield.fill",
                title: "Grant Permissions",
                subtitle: "Solace needs these to protect your focus."
            )

            VStack(spacing: 12) {
                permissionRow(
                    icon: "apps.iphone",
                    title: "Screen Time",
                    body: "Block distracting apps and websites.",
                    granted: permissionState.familyControls,
                    action: { await permissionState.requestFamilyControls() }
                )

                permissionRow(
                    icon: "wave.3.right",
                    title: "NFC Reader",
                    body: "Scan your tag to start and end sessions.",
                    granted: permissionState.nfcAvailable,
                    readOnly: true
                )

                if #available(iOS 26.0, *) {
                    permissionRow(
                        icon: "alarm.fill",
                        title: "Alarms",
                        body: "Schedule NFC-gated wake-up alarms.",
                        granted: permissionState.alarmKit,
                        action: { await permissionState.requestAlarmKit() }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var finishStep: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 160, height: 160)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 110, weight: .semibold))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: step)
            }

            VStack(spacing: 10) {
                Text("You're Ready.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Let's build the focus habit.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Shared views

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.cyan.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.bottom, 6)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private func featureRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        body: String,
        granted: Bool,
        readOnly: Bool = false,
        action: (() async -> Void)? = nil
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else if readOnly {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            } else if let action {
                Button {
                    Task { await action() }
                } label: {
                    Text("Allow")
                        .font(.footnote.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack(spacing: 12) {
            if step > 0 && step < totalSteps - 1 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Text("Back")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                }
            }

            Button {
                withAnimation {
                    if step < totalSteps - 1 {
                        step += 1
                    } else {
                        onboardingComplete = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(primaryButtonTitle)
                        .fontWeight(.bold)
                    if step < totalSteps - 1 {
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case 0: return "Get Started"
        case 1: return "Continue"
        case 2: return "Next"
        case 3: return "Continue"
        default: return "Enter Solace"
        }
    }
}

// MARK: - Permission state

@MainActor
final class PermissionState: ObservableObject {
    @Published var familyControls: Bool = false
    @Published var nfcAvailable: Bool = NFCNDEFReaderSession.readingAvailable
    @Published var alarmKit: Bool = false

    func refresh() async {
        familyControls = AuthorizationCenter.shared.authorizationStatus == .approved
        nfcAvailable = NFCNDEFReaderSession.readingAvailable
        if #available(iOS 26.0, *) {
            alarmKit = AlarmManager.shared.authorizationState == .authorized
        }
    }

    func requestFamilyControls() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Onboarding: FamilyControls auth failed:", error)
        }
        await refresh()
    }

    @available(iOS 26.0, *)
    func requestAlarmKit() async {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            alarmKit = true
            return
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                alarmKit = state == .authorized
            } catch {
                print("Onboarding: AlarmKit auth failed:", error)
            }
        default:
            alarmKit = false
        }
    }
}
