//
//  ReportView.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 25.07.2024.
//

import SwiftUI

struct ReportView: View {
	private enum ViewChoice: String {
		case charts
		case list
	}
	
	@State private var viewChoice: ViewChoice = .charts

	var body: some View {
			Picker("", selection: $viewChoice) {
				Text("Charts").tag(ViewChoice.charts)
				Text("List").tag(ViewChoice.list)
			}
			.pickerStyle(.segmented)
			.padding()

			Group {
				switch viewChoice {
				case .charts:
					ChartsView()
				case .list:
					ReportListView()
				}
			}
#if os(iOS)
		.onAppear {
			// Reset segmented pickers to be even (Necessary for long languages)
			UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
		}
#endif
	}
}

#Preview {
    ReportView()
}
