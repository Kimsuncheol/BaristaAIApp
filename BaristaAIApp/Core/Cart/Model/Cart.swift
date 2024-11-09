//
//  Cart.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/5/24.
//

import Foundation

struct Cart: Identifiable, Codable, Hashable {
    let id: String
    var customerEmail: String
    let drink_id: String
    var name: String
//    let image: String?
    var price: Int
    var totalPrice: Int { price * quantity }
    var quantity: Int
    var selected: Bool = true
    
    init(id: String, customerEmail: String, drink_id: String, name: String, /* image: String?, */price: Int, quantity: Int, selected: Bool) {
           self.id = id
        self.customerEmail = customerEmail
           self.drink_id = drink_id
           self.name = name
//           self.image = image
           self.price = price
           self.quantity = quantity
           self.selected = selected
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "customerEmail": customerEmail,
            "drink_id": drink_id,
            "name": name,
//            "image": image as Any,      // 이걸 주목할 것
            "price": price,
            "totalPrice": totalPrice,
            "quantity": quantity,
            "selected": selected
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let customerEmail = dictionary["customerEmail"] as? String,
              let drink_id = dictionary["drink_id"] as? String,
              let name = dictionary["name"] as? String,
//              let image = dictionary["image"] as? String?,
              let price = dictionary["price"] as? Int,
              let quantity = dictionary["quantity"] as? Int,
              let selected = dictionary["selected"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.customerEmail = customerEmail
        self.drink_id = drink_id
        self.name = name
//        self.image = image
        self.price = price
        self.quantity = quantity
        self.selected = selected
    }
}
