//
//  MockSearchBar.swift
//  BaristaAIAppForManager
//
//  Created by 김선철 on 10/11/24.
//

import SwiftUI

struct MockSearchBar: View {
    var body: some View {
        Text("Search")
            .foregroundColor(.gray)
            .padding()
            .frame(width: UIScreen.main.bounds.width - 20, alignment: .leading)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .trailing, content: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.gray.opacity(0.7))
                    .padding()
            })
    }
}

#Preview {
    ContentView()
}
