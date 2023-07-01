//
//  SettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Combine
import SwiftUI

struct SettingsView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("idleDetect") private var idleDetect = false
    @AppStorage("idleLimit") private var idleLimit = 6
    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25
        
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
            
            PomodoroSettingsView()
                .tabItem {
                    Label("Pomodoro", systemImage: "stopwatch")
                }
        }
        .padding(20)
        .onAppear() {
            Task {
                try await storeModel.fetchProducts()
            }
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

