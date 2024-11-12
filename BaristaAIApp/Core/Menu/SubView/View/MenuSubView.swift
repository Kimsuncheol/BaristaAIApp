//
//  MenuSubView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/27/24.
//

import SwiftUI

struct MenuSubView: View {
    let user: User?
    var type: String
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var isTopicSelectedIndex: Int
    @Binding var NavigateToLogin: Bool
    
    @ObservedObject var viewModel: MenuViewModel
    @ObservedObject var myFavoriteViewModel: MyFavoriteViewModel
//    @StateObject var myFavoriteViewModel = MyFavoriteViewModel()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.menu.indices, id: \.self) { index in
                    CardView(user: user, drink: $viewModel.menu[index], NavigateToLogin: $NavigateToLogin, myFavoriteViewModel: myFavoriteViewModel)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            viewModel.fetchMenu(type)
        }
    }
}

#Preview {
    ContentView()
}

struct CardView: View {
    let user: User?
    let imageWidth = UIScreen.main.bounds.width / 2 - 20
    @Binding var drink: Drink
    @Binding var NavigateToLogin: Bool
    
//    @ObservedObject var myFavoriteViewModel: MyFavoriteViewModel
    @ObservedObject var myFavoriteViewModel: MyFavoriteViewModel
    @State private var isTapped = false
    @State private var animated = false
    @State private var navigateToOrder = false
    
    var isFavorited: Bool {
        guard let email = user?.email else { return false }
        return myFavoriteViewModel.favorites.contains(where: { $0.drink_id == drink.id && $0.customerEmail == email })
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            //                            Image("")
            //                                .resizable()
            ZStack(alignment: .topTrailing) {
//                Image("")
                NavigationLink(destination: OrderView(user: user, drink: $drink)) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: imageWidth)
                        .foregroundColor(Color.blue.opacity(0.5))
                        .aspectRatio(1 / 1.1, contentMode: .fit)
                }
                
                ZStack {
                    ForEach(0..<6) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 4, height: .random(in: 10...30))
                            .foregroundStyle(.pink)
                            .offset(y:animated ? -70 : 0  )
                            .rotationEffect(.degrees(Double(i) * 60))
                            .scaleEffect(animated ? 1 : 0)
                            .opacity(animated ? 0 : 1)
                    }
                    
                    Image(systemName:isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .pink : .red)
                        .contentTransition(.symbolEffect)
                        .font(.title)
                        .onTapGesture {
                            if let email = user?.email {
                                if isFavorited {
                                    if let favoriteToRemove = myFavoriteViewModel.favorites.first(where: { $0.drink_id == drink.id && $0.customerEmail == email}) {
                                        myFavoriteViewModel.removeFavorite(id: favoriteToRemove.id, customerEmail: email)
                                    }
                                } else {
                                    myFavoriteViewModel.addFavorite(drink: drink, customerEmail: email)
                                }
                                
                                withAnimation(.spring(duration: 1)) {
                                    animated.toggle()
                                }
                            } else {
                                // 로그인 안한 경우 로그인 먼저 권유
                                NavigateToLogin = true
                            }
                        }
                }
                .padding(8)
            }
            .frame(width: imageWidth, height: imageWidth)
            .background(Color.blue.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 10)
            
            Text(drink.name)
                .font(.system(size: 18).bold())
            
            Spacer()
        }
        .frame(width: imageWidth, height: imageWidth + 60)
        .onAppear {
            myFavoriteViewModel.fetchFavorites(customerEmail: user?.email ?? "")
        }
    }
}
