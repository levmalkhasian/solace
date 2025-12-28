//
//  AlarmView.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/20/25.
//

import SwiftUI
import AlarmKit

struct AlarmView: View {
    @ObservedObject var vm: FocusViewModel
    @State private var isAlarmEnabled = false
    var lastWakeTime: String?
    
    // ALARM TAB
    var body: some View {
        VStack {
            Text("Alarm")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 30)
            
            Spacer()
            VStack {
                if #available(iOS 26.0, *) {
                    let stopButton = AlarmButton(
                        text: "Dismiss",
                        textColor: .white,
                        systemImageName: "stop.circle"
                    )
                } else {
                    // Fallback on earlier versions
                }
                Toggle("Alarm", isOn: $isAlarmEnabled)
                    .padding()
                
                Text("Status: \(isAlarmEnabled ? "Enabled" : "Disabled")")
//                Text("Last Wake Time: 7:03 AM")
//                Text("Streak: 4 days")
//                Text("Average snooze time: 1m 12s")
            }
            .font(.title2)
           
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
            
        }
    }
