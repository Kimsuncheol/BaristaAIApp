//
//  MyFavoriteModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/14/24.
//

import Foundation

struct MyFavorite: Identifiable, Hashable, Codable, Equatable {
    var id: String
    var drink_id: String
    var customerEmail: String
    var name: String
    let image: String?
    let flavor_profile: [String]
    let type: String            // drink type
    let temperature: String     // Hot or Cold
    let is_lactose_free: Bool   // 유당 유무
    var description: String     // 음료 설명
    let price: Int              // 음료 가격
    var is_favorite: Bool?       // 즐겨찾기 여부
    
    // Custom initializer
    init(id: String, drink_id: String, customerEmail: String, name: String, image: String?, flavor_profile: [String], type: String, temperature: String, is_lactose_free: Bool, description: String, price: Int, is_favorite: Bool?) {
        self.id = id
        self.drink_id = drink_id
        self.customerEmail = customerEmail
        self.name = name
        self.image = image
        self.flavor_profile = flavor_profile
        self.type = type
        self.temperature = temperature
        self.is_lactose_free = is_lactose_free
        self.description = description
        self.price = price
        self.is_favorite = is_favorite
    }
    
    // Create a dictionary representation for Firestore
    var dictionary: [String: Any] {
        return [
            "id": id,
            "drink_id": drink_id,
            "customerEmail": customerEmail,
            "name": name,
            "image": image as Any, // Optional 처리
            "flavor_profile": flavor_profile,
            "type": type,
            "temperature": temperature,
            "is_lactose_free": is_lactose_free,
            "description": description,
            "price": price,
            "is_favorite": is_favorite!     //  이것을 조심해야 할 것
        ]
    }
    
    // Initialize from a dictionary (for Firestore decoding)
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let drink_id = dictionary["drink_id"] as? String,
              let customerEmail = dictionary["customerEmail"] as? String,
              let name = dictionary["name"] as? String,
              let flavor_profile = dictionary["flavor_profile"] as? [String],
              let type = dictionary["type"] as? String,
              let temperature = dictionary["temperature"] as? String,
              let is_lactose_free = dictionary["is_lactose_free"] as? Bool,
              let description = dictionary["description"] as? String,
              let price = dictionary["price"] as? Int,
              let is_favorite = dictionary["is_favorite"] as? Bool? else {
            return nil
        }
        
        self.id = id
        self.drink_id = drink_id
        self.customerEmail = customerEmail
        self.name = name
        self.flavor_profile = flavor_profile
        self.type = type
        self.temperature = temperature
        self.is_lactose_free = is_lactose_free
        self.description = description
        self.price = price
        self.is_favorite = is_favorite
        
        // `image`는 Optional이므로 따로 처리
        self.image = dictionary["image"] as? String
    }
}
