//
//  StatsView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var vm: FocusSessionManager
    
    // STATS TAB
    var body: some View {
        VStack {
            Text("Stats")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)
            
            Spacer()
            VStack {
                Text("Today: \(vm.timeElapsedToday.asClock)")
                Text("Last Session: \(vm.lastSessionTime.asClock)")
                Text("This Week: \(vm.lastSessionTime.asClock)") // add weekly time
            }
            .font(.title2)
           
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
            
        }
    }
