//
//  FocusView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

struct FocusView: View { // Focus Mode View
    @ObservedObject var vm: FocusSessionManager
    @ObservedObject var shieldManager: ShieldManager // Pass in shieldManager
    let nfcManager: NFCManager

    var body: some View {
        VStack {
            Button {
                nfcManager.startScan(prompt: "Scan to End Focus Mode") { success in
                    if success {
                        Task { @MainActor in
                            shieldManager.clearShield()
                            vm.endFocus()
                        }
                    } else {
                        print("Scan failed. Please try again.")
                    }
                }
            } label: {
                Text("End Focus")
                    .foregroundColor(.red)
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 2)
                        )
            }
            // Remove potentially?
            Text("Focus Mode: ON")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 10)
            Text("This Session: \(vm.timeElapsed.asClock)")
                .foregroundColor(.gray)
            Text("Today: \(vm.timeElapsedToday.asClock)")
                .foregroundColor(.gray)
            
        }
    }
}
