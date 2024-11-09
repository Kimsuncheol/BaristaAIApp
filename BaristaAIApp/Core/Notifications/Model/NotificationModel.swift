//
//  NotificationModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/9/24.
//

import Foundation
import FirebaseFirestore

struct NotificationModel: Identifiable, Codable, Equatable {
    var id: String                      // 주문 ID이기도 하지만 신제품 ID가 되기도 함.
    var type: String                    // 주문이면 order, 신제품이면 roll-out이 저장될 거임
    var customerEmail: String
    let title: String
    var message: String
    var time: Date
    var isRead: Bool
    var isChecked: Bool = false
    var status: String
    var isTakenout: Bool        // = false 이거 일단 삭제
    var takenoutTime: Date?
    
    // Firestore 저장을 위한 초기화
    init(id: String, type: String, customerEmail: String, title: String, message: String, time: Date, isRead: Bool, status: String, isTakenout: Bool) {
        self.id = id
        self.type = type
        self.customerEmail = customerEmail
        self.title = title
        self.message = message
        self.time = time
        self.isRead = isRead
        self.status = status
        self.isTakenout = isTakenout
//        self.isTakenout = isTakenout
//        self.takenoutTime = takenoutTime
   }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "type": type,
            "customerEmail": customerEmail,
            "title": title,
            "message": message,
            "time": time,
            "isRead": isRead,
            "status": status,
            "isTakenout": isTakenout,
            "takenoutTime": takenoutTime ?? NSNull()
        ]
    }
    
    // Equatable 프로토콜을 따르기 위해 구현
    static func == (lhs: NotificationModel, rhs: NotificationModel) -> Bool {
        return lhs.id == rhs.id // ID를 통해 비교
    }
}
