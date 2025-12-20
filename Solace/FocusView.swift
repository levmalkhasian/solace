//
//  FocusView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import SwiftUI

struct FocusView: View { // Focus Mode View
    @ObservedObject var vm: FocusViewModel
    @ObservedObject var shieldManager: ShieldManager // pass in shieldManager
    let nfcManager: NFCManager

    
    var body: some View {
        VStack {
            Text("Focus Mode: ON")
            Text("This Session: \(vm.timeElapsed.asClock)")
            Text("Today: \(vm.timeElapsedToday.asClock)")
            Button {
                nfcManager.startScan(prompt: "Scan to End Focus") { success in
                    if success {
                        shieldManager.clearShield() // uncomment later
                        vm.endFocus()
                        // call function here
                    } else {
                        print("Scan failed.")
                    }
                }
            } label: {
                Text("End Focus")
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                        )
            }
        }
        
    }
}
