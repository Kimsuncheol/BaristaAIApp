//
//  SearchBar.swift
//  BaristaAIAppForManager
//
//  Created by 김선철 on 10/11/24.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
//    var previousViewName: String
    
    var body: some View {
        TextField("Search", text: $searchText)
            .padding()
            .frame(width: UIScreen.main.bounds.width  - 20)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .trailing, content: {
                Button {
                    print("search")
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.gray.opacity(0.7))
                        .padding()
                }
            })
    }
}

#Preview {
    ContentView()
}
