//
//  SettingsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var vm: FocusViewModel
    @ObservedObject var shieldManager: ShieldManager
    
    // SETTINGS TAB
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Spacer()
            VStack {
                Text("Login")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                Text("Coming soon")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                Button {
                    let didUnblock = shieldManager.emergencyUnblock() // > 0 unblocks left
                    
                    if didUnblock == true {
                        vm.endFocus() // End focus mode so we arent stuck. 
                    }
                    else {
                        print("You’ve used all 3 emergency unblocks.")
                    }
                    
                } label: {
                    Text("Emergency Unblock")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}
