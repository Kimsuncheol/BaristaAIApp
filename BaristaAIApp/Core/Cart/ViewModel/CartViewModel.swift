//
//  CartViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/5/24.
//

import SwiftUI
import FirebaseFirestore

class CartViewModel: ObservableObject {
    @Published var cartItems: [Cart] = []
    @Published var isLoading: Bool = false  // 로딩 상태 추가
    @Published var alertMessage: String = ""

    private var db = Firestore.firestore()

    // Fetch all saved drink data from cart
    func fetchCart(customerEmail: String?) {
        guard !isLoading else { return }  // 중복 호출 방지
        isLoading = true
        db.collection("cart").whereField("customerEmail", isEqualTo: customerEmail!).getDocuments { querySnapshot, error in
            DispatchQueue.main.async {  // UI 업데이트는 메인 스레드에서 실행
                self.isLoading = false

                if let error = error {
                    print("Error fetching cart: \(error.localizedDescription)")
                    return
                }

                self.cartItems = querySnapshot?.documents.compactMap { document -> Cart? in
                    try? document.data(as: Cart.self)
                } ?? []
            }
        }
    }

    // Add or update a drink in the cart
    func insertOrUpdateCartItem(drink: Cart, count: Int, customerEmail: String) {
        let cartRef = db.collection("cart").whereField("name", isEqualTo: drink.name).whereField("customerEmail", isEqualTo: customerEmail)

        cartRef.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return } // self가 nil이면 리턴
            
            if let error = error {
                print("Error checking cart: \(error.localizedDescription)")
                return
            }

            if let documents = querySnapshot?.documents, !documents.isEmpty {
                if let document = documents.first {
                    let existingCartData = document.data()
                    let existingQuantity = existingCartData["quantity"] as? Int ?? 0

                    // 수량이 업데이트되지 않은 경우
                    if existingQuantity == count {
                        self.alertMessage = "Drink quantity is not updated."
                        print("Quantity is not updated")
                        return
                    }

                    // 수량이 변경되었을 경우 업데이트
                    let newQuantity = count
                    self.db.collection("cart").document(document.documentID).updateData(["quantity": newQuantity]) { error in
                        if let error = error {
                            self.alertMessage = "Error updating cart item: \(error.localizedDescription)"
                            print("Error updating cart item: \(error.localizedDescription)")
                        } else {
                            self.alertMessage = "Drink quantity updated successfully."
                            print("Cart item updated successfully")
                        }
                    }
                }
            } else {
                
                // 장바구니에 새 아이템 추가
//                let newCartItem = Cart(id: UUID().uuidString, customerEmail: customerEmail, drink_id: drink.id, name: drink.name, price: Int(drink.price), quantity: count, selected: true)
                
                do {
//                    try self.db.collection("cart").document(newCartItem.id).setData(from: newCartItem) { error in
                    try self.db.collection("cart").document(drink.id).setData(from: drink) { error in
                        if let error = error {
                            self.alertMessage = "Error adding cart item: \(error.localizedDescription)"
                            print("Error adding cart item: \(error.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
                                self.cartItems.append(drink)  // 로컬에 아이템 추가
                                self.alertMessage = "Drink added to cart successfully."
                                print("Item added to cart successfully")
                            }
                        }
                    }
                } catch {
                    self.alertMessage = "Error encoding cart item: \(error.localizedDescription)"
                    print("Error encoding cart item: \(error.localizedDescription)")
                }
            }
        }
    }

    // Update the quantity of a cart item
    func updateQuantity(for cartItem: Cart, newQuantity: Int) {
        let cartItemId = cartItem.id
        
        // Firestore에 업데이트할 데이터
        let updatedData: [String: Any] = ["quantity": newQuantity]
        
        db.collection("cart").document(cartItemId).updateData(updatedData) { error in
            if let error = error {
                print("Error updating quantity: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    // 로컬에서 해당 아이템의 수량을 업데이트
                    if let index = self.cartItems.firstIndex(where: { $0.id == cartItemId }) {
                        self.cartItems[index].quantity = newQuantity
                    }
                }
            }
        }
    }

    // Remove an item from the cart
    func removeFromCart(_ cartItem: Cart) {
        let cartItemId = cartItem.id
        
        db.collection("cart").document(cartItemId).delete { error in
            if let error = error {
                print("Error removing from cart: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    if let index = self.cartItems.firstIndex(where: { $0.id == cartItemId }) {
                        self.cartItems.remove(at: index)
                    }
                }
            }
        }
    }

    // Clear all items in the cart
    func clearPurchasedDrinks() {
        db.collection("cart").whereField("selected", isEqualTo: true).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error clearing cart: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else { return }
            
            // 각 문서를 삭제
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting cart item: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            // 로컬의 cart에서 해당 아이템 제거
                            self.cartItems.removeAll { $0.id == document.documentID }
                        }
                    }
                }
            }
        }
    }
}
