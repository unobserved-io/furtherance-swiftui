//
//  TextWithBadge.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 7/3/24.
//

import SwiftUI

struct TextWithBadge: View {
    var content: String
    
    @ObservedObject var storeModel = StoreModel.shared
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        HStack {
            Text(content)
            if storeModel.purchasedIds.isEmpty {
                Text("PRO")
                    .padding(.vertical, 3.0)
                    .padding(.horizontal, 8.0)
                    .foregroundStyle(.background)
                    .background(RoundedRectangle(cornerRadius: 20.0).fill(.accent))
            }
        }
        
    }
}

#Preview {
    TextWithBadge("Text")
}
