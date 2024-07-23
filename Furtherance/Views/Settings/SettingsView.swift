//
//  SettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/24/23.
//

import Combine
import SwiftUI

struct SettingsView: View {
    @ObservedObject var storeModel = StoreModel.shared

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
        .frame(width: 400, height: 450)
        .onAppear {
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
