//
//  CartView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI
import PassKit
import Firebase

struct CartView: View {
    let user: User?
    @State private var selectedItems: [Cart] = []
    @State private var totalPrice: Int = 0
    @State private var totalCount: Int = 0
    @State private var quantities: [String: Int] = [:]
    @State private var isPresented: Bool = false
    @State private var paymentCompleted: Bool = false
    @State private var isSaving: Bool = false
    
    @StateObject private var viewModel = CartViewModel()
    @StateObject private var paymentHistoryViewModel = PaymentHistoryViewModel()

    // Create an instance of the helper class
    private let applePayHandler = ApplePayHandler()
    
    var body: some View {
        VStack {
            List {
                ForEach($viewModel.cartItems, id: \.id) { item in
                    CartItemView(item: item, quantities: $quantities, updateTotals: updateTotals, removeItem: removeItem)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Summary")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                HStack(spacing: 20) {
                    HStack {
                        Text("Price")
                        
                        Spacer()
                    }
                    .frame(width: 100)
                    
                    Text("\(totalPrice) KRW")
                }
                
                HStack(spacing: 20) {
                    HStack {
                        Text("Count")
                        
                        Spacer()
                    }
                    .frame(width: 100)
                    
                    Text("\(totalCount)")
                }
                .padding(.bottom, 10)
                
                PayWithApplePayButton(.order, action: {
                    applePayHandler.startApplePayProcess(totalPrice: totalPrice)
                    
                    // paymentToken을 받는 클로저 구현
                    applePayHandler.onPaymentTokenReceived = { paymentToken in
                        selectedItems = viewModel.cartItems.filter { $0.selected }.map { item in
                            var updatedItem = item
                            updatedItem.quantity = quantities[item.id] ?? 1
                            return updatedItem
                        }
                        
                        updateTotals()
                        
                        Task {
                            await paymentHistoryViewModel.savePaymentHistory(items: selectedItems, totalPrice: totalPrice, customerEmail: user!.email, paymentToken: paymentToken)
                        }
                        
                        DispatchQueue.main.async {
                            paymentCompleted = true
                        }
                    }
                    
                    applePayHandler.onCompletion = {
                        // 결제 완료 후 추가 작업이 필요하면 여기에 작성 가능합니다.
                    }
                })
                .payWithApplePayButtonStyle(.whiteOutline)
                .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                .navigationDestination(isPresented: $paymentCompleted) {
                    CheckOutCompleteView(user: user, purchasedCartItems: selectedItems, totalPrice: totalPrice, totalCount: totalCount)
                }
            }
            .padding()
            .font(.system(size: 20, weight: .bold))
        }
        .padding(.vertical, 20)
        .onAppear {
            if user?.isCurrentUser == true {
                viewModel.fetchCart(customerEmail: user!.email)
            }
        }
        .onChange(of: viewModel.cartItems) {
            updateTotals()
            initializeQuantities()
        }
        .onChange(of: quantities) {
            updateTotals()
        }
        .onDisappear {
            Task {
                isSaving = true
                await saveQuantitiesToFirebase()
                isSaving = false
            }
        }
        .disabled(isSaving)
    }
    
    private func initializeQuantities() {
        quantities = viewModel.cartItems.reduce(into: [String: Int]()) { result, item in
            result[item.id] = item.quantity
        }
    }
    
    // Function to update total price and count
    private func updateTotals() {
        totalCount = viewModel.cartItems.filter { $0.selected }.reduce(0) { result, item in
            let quantity = quantities[item.id] ?? 1
            return result + quantity
        }
        
        totalPrice = viewModel.cartItems.filter { $0.selected }.reduce(0) { result, item in
            let quantity = quantities[item.id] ?? 1
            return result + item.price * quantity
        }
    }
    
    // It's a function that make changed data into Firebase when quantities are changed
    @MainActor
    private func saveQuantitiesToFirebase() async {
        let db = Firestore.firestore()
        for item in viewModel.cartItems {
            let quantity = quantities[item.id] ?? item.quantity
            let cartItemsRef = db.collection("cart").document(item.id)
            do {
                try await cartItemsRef.updateData(["quantity": quantity])
                print("Quantity for \(item.name) updated to \(quantity)")
            } catch {
                print("Failed to update quantity to Firebase for \(item.name): \(error.localizedDescription)")
            }
        }
    }
    
    // Function to remove an item from the cart
    private func removeItem(_ item: Cart) {
        viewModel.removeFromCart(item)
    }
}

#Preview {
    ContentView()
}

struct CartItemView: View {
    @Binding var item: Cart
    @Binding var quantities: [String: Int]
    var updateTotals: () -> Void
    var removeItem: (_ item: Cart) -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            VStack {
                // Placeholder for image
            }
            .frame(width: 100, height: 100)
            .background(Color.red.opacity(0.2))
            
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name)
                        .font(.headline.bold())
                    
                    Spacer()
                    
                    Toggle(isOn: $item.selected) {
                        EmptyView()
                    }
                    .toggleStyle(CheckboxToggleStyle(style: .circle))
                    .foregroundColor(.purple)
                    .onChange(of: item.selected) {
                        updateTotals()
                    }
                }
                
                Text("\(Int(item.price)) KRW")
                    .font(.subheadline)
                
                Stepper(value: Binding(
                    get: { quantities[item.id] ?? 1 },
                    set: { quantities[item.id] = $0
                        updateTotals()
                    }
                ), in: 1...10) {
                    Text("Quantity: \(quantities[item.id] ?? 1)")
                }
            }
        }
        .swipeActions(allowsFullSwipe: true) {
            Button(role: .destructive) {
                removeItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
