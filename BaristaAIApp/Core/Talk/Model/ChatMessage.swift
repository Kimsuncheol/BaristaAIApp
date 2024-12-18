//
//  ChatMessage.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var text: String
//    var customerEmail: String?
    var createdAt: Date
    var senderId: String
    var senderName: String
    var receiverId: String
    var receiverName: String
    
    // 보낸 시간을 포맷팅하는 메서드 추가
   func formattedTime() -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "hh:mm a" 
       return formatter.string(from: createdAt)
   }
}
