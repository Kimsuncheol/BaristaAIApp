//
//  OrderView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/26/24.
//

import SwiftUI
import PassKit
import FirebaseFirestore

struct OrderView: View {
    let user: User?
    @Binding var drink: Drink
    var width = UIScreen.main.bounds.width
    @State var count: Int = 1
    @State var selectedItem: [Cart] = []
    @State private var paymentCompleted: Bool = false
    @State private var showAlert: Bool = false
    @State private var showSuccessInsertOrderDataIntoCart: Bool = false
    @State private var navigateToCart: Bool = false
    @State private var isTapped = false
    @State private var animated = false
    
//    @State var IsContainedMyFavorite: Bool = false
    var isFavorited: Bool {
        guard let email = user?.email else { return false }
        return myFavoriteViewModel.favorites.contains(where: { $0.drink_id == drink.id && $0.customerEmail == email })
    }
    
    
    @State var NavigateToLogin: Bool = false

    @StateObject private var paymentHistoryViewModel = PaymentHistoryViewModel()
    @StateObject private var cartViewModel = CartViewModel()  // CartViewModel 인스턴스 생성
    
    @StateObject var myFavoriteViewModel = MyFavoriteViewModel()

    var totalPrice: Int { return drink.price * count }
    
    private let applePayHandler = ApplePayHandler()
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ZStack(alignment: .topTrailing) {
                        VStack {
                            // 여기에 이미지 로드 코드를 추가할 수 있습니다.
                        }
                        .frame(width: width, height: width)
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
                    .frame(width: width, height: width)
                    .background(Color.blue.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text(drink.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text("\(drink.price) KRW")
                            .font(.system(size: 20))
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text(drink.description)
                            .font(.system(size: 20))
                    }
                    .padding()
                }
                .frame(width: width)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("\(totalPrice) KRW")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.8))
                
                Stepper(value: $count, in: 1...10) {
                    Text("Quantity: \(count)")
                }
                
                HStack {
                    ZStack {
                        Image(systemName: "cart.badge.plus")
                            .resizable()
                            .frame(width: 35, height: 35)
                    }
                    .padding(7.5)
                    .foregroundColor(.black)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.black, lineWidth: 1)
                    }
                    .onTapGesture {
                        if let email = user?.email {
                            // drink_id 를 유심히 볼 것! 음료 가격이 변동되었을 때 cart에 저장되어 있는 상태임에도 cart에 있는 그 음료의 가격과 동기화 안되어 있음
                            print("orderview - drink_id: \(String(describing: drink.id))")
                            let newCartItem = Cart(id: UUID().uuidString, customerEmail: email, drink_id: drink.id!, name: drink.name, price: drink.price, quantity: count, selected: true)
                            
                            insertOrUpdateCartItem(cartItem: newCartItem) // 카트 아이템 객체 전달
                        } else {
                            // 로그인 안한 경우 로그인 먼저 권유
                            NavigateToLogin = true
                        }
                    }
                    
                    Spacer()
                    
                    PayWithApplePayButton(.order, action : {
                        if let email = user?.email {
                            applePayHandler.startApplePayProcess(totalPrice: totalPrice)
                            
                            // paymentToken을 받는 클로저 구현
                            applePayHandler.onPaymentTokenReceived = { paymentToken in
                                let newCartItem = Cart(id: UUID().uuidString, customerEmail: email, drink_id: drink.id!, name: drink.name, price: drink.price, quantity: count, selected: true)
                                
                                selectedItem.append(newCartItem)
                                
                                Task {
                                    await paymentHistoryViewModel.savePaymentHistory(items: selectedItem, totalPrice: totalPrice, customerEmail: email, paymentToken: paymentToken)
                                }
                                
                                paymentCompleted = true
                            }
                            
                            applePayHandler.onCompletion = {
                                // 결제 완료 후 추가 작업이 필요하면 여기에 작성 가능합니다.
                            }
                        } else {
                            // 로그인 안한 경우 로그인 먼저 권유
                            NavigateToLogin = true
                        }
                    })
                    .payWithApplePayButtonStyle(.whiteOutline)
                    .frame(width: UIScreen.main.bounds.width - 100, height: 50)
                    .navigationDestination(isPresented: $paymentCompleted) {
                        CheckOutCompleteView(user: user, purchasedCartItems: selectedItem, totalPrice: totalPrice, totalCount: count)
                    }
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $NavigateToLogin) {
            LoginView()
        }
        .alert(isPresented: $showAlert) {
            // I need to add
            if showSuccessInsertOrderDataIntoCart {
                return Alert(
                    title: Text("Cart Update"),
                    message: Text(cartViewModel.alertMessage),
                    primaryButton: .default(Text("Move to Cart")) {
                        navigateToCart = true
                        showAlert = false
                        cartViewModel.alertMessage = ""
                        showSuccessInsertOrderDataIntoCart = false
                    },
                    secondaryButton: .cancel(Text("Continue Shopping")) {
                        showAlert = false
                        cartViewModel.alertMessage = ""
                        showSuccessInsertOrderDataIntoCart = false
                    }
                )
                
            } else {
                return Alert(
                    title: Text("Cart Update"),
                    message: Text(cartViewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        showAlert = false
                        cartViewModel.alertMessage = ""
                        showSuccessInsertOrderDataIntoCart = false
                    }
                )
            }
        }
        .navigationDestination(isPresented: $navigateToCart) {
            CartView(user: user)
        }
        .onChange(of: cartViewModel.alertMessage) {
            // alertMessage가 업데이트될 때만 알림을 표시
            if !cartViewModel.alertMessage.isEmpty {
                if cartViewModel.alertMessage.contains("cart successfully.") || cartViewModel.alertMessage.contains("updated successfully.") {
                    showSuccessInsertOrderDataIntoCart = true
                }
                showAlert = true
            }
        }
        .onAppear {
//            if let email = user?.email {
//                IsContainedMyFavorite = myFavoriteViewModel.favorites.contains(where: { $0.drink_id == drink.id && $0.customerEmail == email })
//                isTapped = IsContainedMyFavorite
//            }
            myFavoriteViewModel.fetchFavorites(customerEmail: user?.email ?? "")
            resetStateVariables()
            selectedItem.removeAll()
        }
    }
    
    private func resetStateVariables() {
        showSuccessInsertOrderDataIntoCart = false
        navigateToCart = false
    }
    
    private func insertOrUpdateCartItem(cartItem: Cart) {
        // CartViewModel의 insertOrUpdateCartItem 호출
        cartViewModel.insertOrUpdateCartItem(drink: cartItem, count: cartItem.quantity, customerEmail: user!.email)
        
        // 메시지가 업데이트된 후에 알림을 트리거
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !cartViewModel.alertMessage.isEmpty {
                if cartViewModel.alertMessage.contains("cart successfully.") || cartViewModel.alertMessage.contains("updated successfully.") {
                    showSuccessInsertOrderDataIntoCart = true
                }
                showAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}
