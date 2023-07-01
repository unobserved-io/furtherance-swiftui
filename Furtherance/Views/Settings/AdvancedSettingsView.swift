//
//  AdvancedSettingsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/1/23.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("idleDetect") private var idleDetect = false
    @AppStorage("idleLimit") private var idleLimit = 6
    
    var body: some View {
        Form {
            Section(header: storeModel.purchasedIds.isEmpty ? Text("Idle (Pro)").bold() : Text("Idle").bold()) {
                HStack {
                    Text("Detect when user is idle")
                    Spacer()
                    Toggle("Detect when user is idle", isOn: $idleDetect)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
                
                HStack {
                    Text("Minutes before user is idle:")
                    Spacer()
                    Text("\(idleLimit)")
                        .bold()
                    Stepper("\(idleLimit)", value: $idleLimit, in: 1...999)
                        .labelsHidden()
                        .disabled(storeModel.purchasedIds.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                .padding()
                .background(colorScheme == .light ? .white.opacity(0.50) : .white.opacity(0.10))
                .cornerRadius(20)
            }
        }
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView()
    }
}
