//
//  ReportsView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/12/23.
//

import SwiftUI

struct ReportsView: View {
    private enum Timeframe {
        case week
        case month
        case thirtyDays
        case oneEightyDays
        case year
        case custom
    }
    
    @State private var timeframe: Timeframe = .thirtyDays
    @State private var sortByTask: Bool = true
    @State private var filterByTask: Bool = true
    @State private var filter: Bool = true
    @State private var filterInput: String = ""
    
    var body: some View {
        List {
            Section {
                Picker("Timeframe", selection: $timeframe) {
                    Text("Past week").tag(Timeframe.week)
                    Text("This month").tag(Timeframe.month)
                    Text("Past 30 days").tag(Timeframe.thirtyDays)
                    Text("Past 180 days").tag(Timeframe.oneEightyDays)
                    Text("Past year").tag(Timeframe.year)
                    Text("Date range").tag(Timeframe.custom)
                }
                
                Picker("Sort by", selection: $sortByTask) {
                    Text("Task").tag(true)
                    Text("Tag").tag(false)
                }
                .pickerStyle(.segmented)
                
                Toggle("Filter", isOn: $filter)
                    .toggleStyle(.switch)
                
                if filter {
                    HStack {
                        Picker("", selection: $filterByTask) {
                            Text("Task").tag(true)
                            Text("Tag").tag(false)
                        }
                        TextField("", text: $filterInput)
                    }
                }
                
                Button("Refresh") {
                    
                }
            }
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
    }
}
