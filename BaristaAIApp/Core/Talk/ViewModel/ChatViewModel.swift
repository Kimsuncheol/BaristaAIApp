//
//  ChatViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [] // 채팅 메시지 목록
    @Published var text: String = "" // 입력된 메시지 내용
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration? // Firestore 리스너를 관리하기 위한 변수
    private let userName = Auth.auth().currentUser?.displayName ?? "User" // 현재 사용자의 이름
    private let chatbotId = "chatbot" // 대화형 엔진의 ID
    let chatbotName = "Barista AI" // 대화형 엔진의 이름

    init() {
        print("customerEmail : \(Auth.auth().currentUser?.email ?? "from chatViewModel - no user")")
        if let customerEmail = Auth.auth().currentUser?.email {     // 이부분도 유의
            fetchMessages(customerEmail: customerEmail)
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // Firestore에서 메시지를 가져오고 실시간 업데이트 감지
    func fetchMessages(customerEmail: String) {
        // 기존 리스너를 제거하여 중복 리스너 방지
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("messages")
            .whereField("senderId", in: [customerEmail, chatbotId])        // 이 부분도 유의
            .whereField("receiverId", in: [customerEmail, chatbotId])
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                self?.messages = querySnapshot?.documents.compactMap { document -> ChatMessage? in
                    try? document.data(as: ChatMessage.self)
                } ?? []
            }
    }
    
    // Firestore에 메시지 전송
    func sendMessage(customerEmail: String?) {
        guard !text.isEmpty else { return }
        
        let newMessage: ChatMessage
        
        // 아랫 부분 100% 오류 발생할 거임. 지금은 탐지를 못하는 중이지만, 모든 customer에게 같은 메시지를 전송하게 될 거라서
        // customerEmail 속성을 없애고 senderId에 customerEmail 넣었으니 아마 오류 해결되었을 듯
        if let customerEmail = customerEmail {
            // 내가 챗봇에게 메시지 보내는 거고
            newMessage = ChatMessage(
                text: text,
//                customerEmail: customerEmail,
                createdAt: Date(),
                senderId: customerEmail,
                senderName: userName,
                receiverId: chatbotId,
                receiverName: chatbotName
            )
        } else {
            // 챗봇으로부터 답장 메시지를 받는 경우임
            newMessage = ChatMessage(
                text: text,
//                customerEmail: "",      // 이거 유의
                createdAt: Date(),
                senderId: chatbotId,
                senderName: chatbotName,
                receiverId: customerEmail!,     // 이거 관심
                receiverName: userName
            )
        }
        
        do {
            _ = try db.collection("messages").addDocument(from: newMessage)
//            self.text = ""   // To reset after transmit a message
            DispatchQueue.main.async {
                self.text = ""   // To reset after transmit a message
            }
        } catch {
            print("Error sending message: \(error)")
        }
    }
}
