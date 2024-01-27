//
//  DockTileContents.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 1/8/24.
//

import SwiftUI

struct DockTileContents: View {    
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
