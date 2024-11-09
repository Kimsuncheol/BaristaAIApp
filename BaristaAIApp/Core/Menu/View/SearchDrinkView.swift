//
//  SearchView.swift
//  BaristaAIAppForManager
//
//  Created by 김선철 on 10/11/24.
//

import SwiftUI

struct SearchDrinkView: View {
    let user: User?
    @ObservedObject private var viewModel = SearchDrinkViewModel()
    @State private var searchText: String = ""
    @State private var selectedDrink: Drink?
    @State private var isNavigatingToOrderView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SearchBar(searchText: $viewModel.query)
                .padding(.horizontal)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.drinks, id: \.self) { drink in
                        Button {
                            selectedDrink = drink
                            isNavigatingToOrderView = true
                        } label: {
                            VStack {
                                Text(drink.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom)
                            }
                            
                        }
                    }
                }
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
        }
        .navigationDestination(isPresented: $isNavigatingToOrderView) {
            if let drink = selectedDrink {
                OrderView(user: user, drink: .constant(drink))
            } else {
                Text("No drink selected") // Fallback view or empty view

            }
        }
    }
}

#Preview {
//    ContentView()
//        .environmentObject(OrderViewModel())
//        .environmentObject(Settings())
}
