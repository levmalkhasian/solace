//
//  SolaceApp.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/16/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct SolaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var focusManager = FocusSessionManager()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("pendingAlarmDismissID") private var pendingAlarmDismissID: String = ""
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingComplete {
                    ContentView()
                        .environmentObject(focusManager)
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: onboardingComplete)
            .task {
                focusManager.refreshToday(now: Date())
                focusManager.restoreSessionIfNeeded()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    focusManager.refreshToday(now: Date())
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !pendingAlarmDismissID.isEmpty },
                set: { if !$0 { pendingAlarmDismissID = "" } }
            )) {
                if #available(iOS 26.0, *) {
                    AlarmDismissContainer(pendingAlarmDismissID: $pendingAlarmDismissID)
                }
            }
        }
    }
}

@available(iOS 26.0, *)
private struct AlarmDismissContainer: View {
    @StateObject private var scheduler = AlarmScheduler()
    @Binding var pendingAlarmDismissID: String

    var body: some View {
        AlarmDismissView(scheduler: scheduler) {
            pendingAlarmDismissID = ""
        }
    }
}
