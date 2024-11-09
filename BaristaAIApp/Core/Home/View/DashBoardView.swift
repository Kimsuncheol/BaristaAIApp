//
//  HomeView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/25/24.
//

import SwiftUI
import InfinitePaging

struct DashBoardView: View {
    let user: User?
    private let colors: [Color] = [.black, .blue, .brown, .cyan, .gray, .indigo, .mint, .yellow, .orange, .purple]
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var currentIndex = 0  // State variable to track the current index
    
    @StateObject var myFavoriteViewModel = MyFavoriteViewModel()
    @StateObject var cartViewModel = CartViewModel()
    @StateObject var viewModel = DashBoardViewModel()
    
    @State private var timer: Timer?    // 타이머 초기화 상태 및 수동 리셋을 위한 상태 변수
    @State var NavigateToLogin: Bool = false
    
    var body: some View {
        VStack(alignment: .center) {
            // myFavoriteViewModel에 contains 함수 구축하여 그 함수에 싹 다 데이터 대입해봐야 할 듯...
            ScrollView(showsIndicators: false) {
                TabView(selection: $currentIndex) {
                    colors[colors.count - 1].tag(-1)
                    ForEach(0..<colors.count, id: \.self) { index in
                        colors[index]
                            .tag(index)  // Assign a tag for each tab
                    }
                    colors[0].tag(colors.count)
                }
                .padding(.bottom, 20)
                .frame(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.height / 2) - 50)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentIndex) {
                    if currentIndex == colors.count {
                        currentIndex = 0
                    } else if currentIndex ==  -1 {
                        currentIndex = colors.count - 1
                    }
                    resetTimer()
                }
                .accessibilityIdentifier("CarouselView")
                
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.drinks.indices, id: \.self) { index in
                        HomeCoffeeCardView(user: user, colors: colors, drink: $viewModel.drinks[index], NavigateToLogin: $NavigateToLogin, myFavoriteViewModel: myFavoriteViewModel)
                    }
                }
            }
            .padding(.horizontal)
            
//            Spacer()
        }
        .fullScreenCover(isPresented: $NavigateToLogin) {
            LoginView()
        }
        .padding(.vertical, 1)
        .onAppear {
            viewModel.fetchDrinks()
            cartViewModel.fetchCart(customerEmail: user?.email ?? "")
            myFavoriteViewModel.fetchFavorites(customerEmail: user?.email ?? "")
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % colors.count
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        startTimer()
    }
}

#Preview {
    ContentView()
        .environmentObject(PaymentHistoryViewModel())
}

struct HomeCoffeeCardView: View {
    let user: User?
    var imageWidth = UIScreen.main.bounds.width / 2 - 20
    let colors: [Color]     // I will remove this code after completing constructing firestore
    @Binding var drink: Drink
    @Binding var NavigateToLogin: Bool
    
    @ObservedObject var myFavoriteViewModel: MyFavoriteViewModel
    @State private var isTapped = false
    @State private var animated = false
    @State private var navigateToOrder = false
//    @State var IsContainedMyFavorite: Bool = false
    
    var isFavorited: Bool {
        guard let email = user?.email else { return false }
        return myFavoriteViewModel.favorites.contains(where: { $0.drink_id == drink.id && $0.customerEmail == email })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
//                Image("")
                NavigationLink(destination: OrderView(user: user, drink: $drink)) {             RoundedRectangle(cornerRadius: 10)
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
            
            NavigationLink(destination: OrderView(user: user, drink: $drink)) {
                VStack(alignment: .leading) {
                    Text(drink.name)
                        .font(.title3.bold())
                    
                    Text("\(drink.price) KRW")
                        .font(.title3.bold())
                    
                    Text(drink.description)
                        .frame(height: 60, alignment: .top) // Set a fixed height for the description text
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    //                        .padding(.top, -(UIScreen.main.bounds.height / 200))
                }
                .foregroundStyle(.black)
            }
        }
        .frame(width: imageWidth)
        .foregroundStyle(.black.opacity(0.5))
    }
}
