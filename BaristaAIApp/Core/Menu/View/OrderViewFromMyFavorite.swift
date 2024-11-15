//
//  OrderViewFromMyFavorite.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/15/24.
//

import SwiftUI
import PassKit
import FirebaseFirestore

struct OrderViewFromMyFavorite: View {
    let user: User?
    @Binding var myfavorite: MyFavorite
    var width = UIScreen.main.bounds.width
    @State var count: Int = 1
    @State var selectedItem: [Cart] = []
    @State private var paymentCompleted: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showSuccessInsertOrderDataIntoCart: Bool = false
    @State private var navigateToCart: Bool = false
    @State private var isTapped = false
    @State private var animated = false
    @State var IsContainedMyFavorite: Bool = false

    @StateObject private var paymentHistoryViewModel = PaymentHistoryViewModel()
    @StateObject private var cartViewModel = CartViewModel() // CartViewModel 인스턴스 생성
    
    @StateObject var myFavoriteViewModel = MyFavoriteViewModel()

    var totalPrice: Int { return myfavorite.price * count }
    
    private let applePayHandler = ApplePayHandler()
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    // 이미지 영역
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
                        }
                        .padding(8)
                    }
                    .frame(width: width, height: width)
                    .background(Color.blue.opacity(0.5))
                    
                    // 제목과 설명
                    VStack(alignment: .leading, spacing: 20) {
                        Text(myfavorite.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text("\(myfavorite.price) KRW")
                            .font(.system(size: 20))
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text(myfavorite.description)
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
                            let newCartItem = Cart(id: UUID().uuidString, customerEmail: email, drink_id: myfavorite.id, name: myfavorite.name, image: myfavorite.image, temperature: myfavorite.temperature, price: myfavorite.price, quantity: count, selected: true)
                            
                            insertOrUpdateCartItem(cartItem: newCartItem)
                        } else {
                            // 로그인 안한 경우 로그인 먼저 권유
                        }
                    }
                    
                    Spacer()
                    
                    PayWithApplePayButton(.order, action : {
                        if let email = user?.email {
                            applePayHandler.startApplePayProcess(totalPrice: totalPrice)
                            
                            // paymentToken을 받는 클로저 구현
                            applePayHandler.onPaymentTokenReceived = { paymentToken in
                                let newCartItem = Cart(id: UUID().uuidString, customerEmail: email, drink_id: myfavorite.id, name: myfavorite.name, image: myfavorite.image, temperature: myfavorite.temperature, price: myfavorite.price, quantity: count, selected: true)
                                
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
        .toolbar {
            // OrderView의 툴바
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CartView(user: user)) {
                    Image(systemName: "cart")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: NotificationView(user: user)) {
                    Image(systemName: "bell")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .alert(isPresented: $showAlert) {
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
                // showAlert는 마지막에 실행되어야 합니다.
                showAlert = true
            }
        }
        .onAppear {
            if let email = user?.email {
                IsContainedMyFavorite = myFavoriteViewModel.favorites.contains(where: { $0.id == myfavorite.id && $0.customerEmail == email })
                isTapped = IsContainedMyFavorite
            }
            resetStateVariables()
            selectedItem.removeAll()
        }
    }
    
    private func resetStateVariables() {
        showSuccessInsertOrderDataIntoCart = false
        navigateToCart = false
    }
    
    private func insertOrUpdateCartItem(cartItem: Cart) {
        if let email = user?.email {
            cartViewModel.insertOrUpdateCartItem(drink: cartItem, count: cartItem.quantity, customerEmail: email)
        }

        // insertOrUpdateCartItem 이후 alertMessage를 확인하고 showAlert를 트리거
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !cartViewModel.alertMessage.isEmpty {
                // 먼저 showSuccessInsertOrderDataIntoCart 값을 업데이트
                if cartViewModel.alertMessage.contains("cart successfully.") || cartViewModel.alertMessage.contains("updated successfully.") {
                    showSuccessInsertOrderDataIntoCart = true
                }
                // 그 후에 showAlert 트리거
                showAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}
