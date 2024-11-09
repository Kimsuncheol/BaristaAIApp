//
//  MyFavoriteView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI

struct MyFavoriteView: View {
    let user: User?
    @StateObject var viewModel = MyFavoriteViewModel()
    
    var body: some View {
        List {
            ForEach($viewModel.favorites, id: \.self) { $favorite in
                NavigationLink(destination: OrderViewFromMyFavorite(user: user, myfavorite: $favorite).navigationBarBackButtonHidden(false)) {
                    MyFavoriteCoffeeCard(drink: favorite)
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        // Remove the item from the list
                        viewModel.removeFavorite(id: favorite.id, customerEmail: user?.email ?? "")
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.vertical, 1)
        .onAppear {
            viewModel.fetchFavorites(customerEmail: user?.email ?? nil)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        return
                    }
                }
        )
    }
}

#Preview {
    ContentView()
//    MyFavoriteView()
}


struct MyFavoriteCoffeeCard: View {
    var drink: MyFavorite
    var imageWidth: CGFloat = 100
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            //                        Image(systemName: drink.image)
            //                            .resizable()
            VStack {
                
            }
            .frame(width: imageWidth, height: imageWidth)
            .background(Color.red.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 10) {
                Text(drink.name)
                    .font(.headline.bold())
                    .lineLimit(1)
                
                Text(drink.description)
                    .font(.subheadline)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 10)
    }
}
