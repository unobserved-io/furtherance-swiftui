//
//  DockTileContents.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 1/8/24.
//

import SwiftUI

struct DockTileContents: View {
//    @Environment(StopWatchHelper.self) private var stopWatchHelper
    
    var body: some View {
        Text(
                timerInterval: (.now) ... (.distantFuture),
                countsDown: false
            )
    }
}

#Preview {
    DockTileContents()
}
