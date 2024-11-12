//
//  PaymentHistoryModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/7/24.
//

import Foundation
import FirebaseFirestore

struct PaymentHistory: Codable, Identifiable {
    var id: String
    var customerEmail: String
    var items: [Cart]
    var totalPrice: Int
    var timestamp: Date
    var status: String
    var paymentTokenData: Data    // 결제 식별자
    
    // Add this initializer to match the call
   init(id: String, customerEmail: String, items: [Cart], totalPrice: Int, timestamp: Date, status: String, paymentTokenData: Data) {
       self.id = id
       self.customerEmail = customerEmail
       self.items = items
       self.totalPrice = totalPrice
       self.timestamp = timestamp
       self.status = status
       self.paymentTokenData = paymentTokenData
   }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "customerEmail": customerEmail,
            "items": items.map { $0.dictionary }, // Assuming Cart has a `dictionary` property
            "totalPrice": totalPrice,
            "timestamp": Timestamp(date: timestamp),
            "status": status,
            "paymentToken": paymentTokenData
        ]
    }
    
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let customerEmail = document["customerEmail"] as? String,
              let itemsData = document["items"] as? [[String: Any]],
              let totalPrice = document["totalPrice"] as? Int,
              let timestamp = document["timestamp"] as? Timestamp else { return nil }
              let status = document["status"] as? String
              let paymentTokenData = document["paymentToken"] as? Data
        
        self.id = id
        self.customerEmail = customerEmail
        self.items = itemsData.compactMap { Cart(dictionary: $0) }
        self.totalPrice = totalPrice
        self.timestamp = timestamp.dateValue()
        self.status = status ?? ""
        if let tokenData = document["paymentToken"] as? Data {
            self.paymentTokenData = tokenData
        } else {
            return nil
        }
    }
}

