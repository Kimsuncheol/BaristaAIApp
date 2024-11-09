//
//  TopView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/23/24.
//

import SwiftUI

struct TopView: View {
    var title: String
    var details: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title.bold())
            Text(details)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
//        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TopView(title: "asdsa", details: "dasdsadasdsa")
}
