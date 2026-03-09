//
//  SolaceApp.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/16/25.
//

import SwiftUI

@main
struct SolaceApp: App {
    @StateObject private var focusManager = FocusSessionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(focusManager)
                .task {
                    focusManager.refreshToday(now: Date())
                  }
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        // App became active (includes after launch + returning from background)
                        focusManager.refreshToday(now: Date())
                    }
                }
        }
    }
}
