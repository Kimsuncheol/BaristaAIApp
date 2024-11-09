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

//func savePaymentHistory(items: [Cart], totalPrice: Int) {
//    let paymentID = UUID().uuidString
//    let paymentHistory = PaymentHistory(id: paymentID, items: items, totalPrice: totalPrice, timestamp: Date())
//    
//    let db = Firestore.firestore()
//    
//    db.collection("payment_history").document(paymentID).setData(paymentHistory.dictionary) { error in
//        if let error = error {
//            print("Error saving payment history: \(error.localizedDescription)")
//        } else {
//            print("Payment history saved successfully.")
//            createOrderCompletionNotification(items: items, totalPrice: totalPrice)
//        }
//    }
//}
//
//func createOrderCompletionNotification(items: [Cart], totalPrice: Int) {
//    let title = "Order Completed"
//    let itemNames = items.map { $0.name }.joined(separator: ", ")
//    let message = "Your order for \(itemNames) totaling \(totalPrice) has been completed."
//    
//    let currentTime = Date()
//    let timeString = timeElapsedString(from: currentTime)
//    
//    let notification = NotificationItem(title: title, message: message, time: timeString, isRead: false)
//    
//    saveNotification(notification: notification)
//}
//
//func timeElapsedString(from date: Date) -> String {
//    let now = Date()
//    let timeInterval = now.timeIntervalSince(date)
//    
//    let minutes = Int(timeInterval / 60)
//    
//    if minutes < 1 {
//        return "Just now"
//    } else {
//        return "\(minutes) mins ago"
//    }
//}
//
//func saveNotification(notification: NotificationItem) {
//    let db = Firestore.firestore()
//    
//    db.collection("notifications").document(notification.id.uuidString).setData([
//        "title" : notification.title,
//        "message" : notification.message,
//        "time" : notification.time,
//        "isRead" : notification.isRead
//    ]) { error in
//        if let error = error {
//            print("Error saving notification: \(error.localizedDescription)")
//        } else {
//            print("Notification saved successfully.")
//        }
//    }
//}
