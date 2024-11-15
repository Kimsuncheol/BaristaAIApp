//
//  ChatViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [] // 채팅 메시지 목록
    @Published var text: String = "" // 입력된 메시지 내용
    @Published var ChatBotMessage: String = ""  // 챗봇 메시지 내용
    @Published var isLoadingResponse: Bool = false
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration? // Firestore 리스너를 관리하기 위한 변수
    private let userName = Auth.auth().currentUser?.displayName ?? "User" // 현재 사용자의 이름
    private let chatbotId = "chatbot" // 대화형 엔진의 ID
    let chatbotName = "Barista AI" // 대화형 엔진의 이름
    private var conversation: [Utterance] = [] // 대화를 저장하는 배열
    private var cancellables = Set<AnyCancellable>()

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
        let userUtterance = Utterance(role: "ROLE_USER", content: text) // 사용자 메시지

        // 아랫 부분 100% 오류 발생할 거임. 지금은 탐지를 못하는 중이지만, 모든 customer에게 같은 메시지를 전송하게 될 거라서
        // customerEmail 속성을 없애고 senderId에 customerEmail 넣었으니 아마 오류 해결되었을 듯
        newMessage = ChatMessage(
            text: text,
//                customerEmail: customerEmail,
            createdAt: Date(),
            senderId: customerEmail,
            senderName: userName,
            receiverId: chatbotId,
            receiverName: chatbotName
        )
        
        do {
            _ = try db.collection("messages").addDocument(from: newMessage)
            DispatchQueue.main.async {
                self.text = ""   // To reset after transmit a message
            }
        } catch {
            print("Error sending message: \(error)")
        }
        
        conversation.append(userUtterance)

        callChatbotAPI(with: text, conversation: conversation, customerEmail: customerEmail)
    }
    
    private func callChatbotAPI(with message: String, conversation: [Utterance], customerEmail: String?) {
        self.isLoadingResponse = true
        
        // 챗봇 API 호출
        guard let url = URL(string: "https://norchestra.maum.ai/harmonize/dosmart") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // 멀티턴 대화를 위한 utterances 배열
        let requestBody = APIRequest(
            app_id: "77e64f9d-a586-5ec4-8b6e-b88a91d56a93",
            name: "sejong_70b_stream",
            item: ["maumgpt-maal2-70b-streamchat"],
            param: [
                Param(
                    utterances: conversation,
                    config: Config(
                        top_p: 0.6,
                        top_k: 1,
                        temperature: 0.9,
                        presence_penalty: 0.0,
                        frequency_penalty: 0.0,
                        repetition_penalty: 1.0
                    )
                )
            ]
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("Error encoding request body: \(error)")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                if let string = String(data: response.data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        print("API 응답: \(string)") // 응답 내용 출력
                        self.isLoadingResponse = false
//                        self.text = string
                    }
                }
                
                return response.data
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error calling API: \(error)")
                    self.isLoadingResponse = false
                }
            }, receiveValue: { [weak self] data in
                if let responseString = String(data: data, encoding: .utf8) {
                    self?.handleChatbotResponse(responseString, customerEmail: customerEmail)
                }
            })
            .store(in: &cancellables)
    }
    
    private func handleChatbotResponse(_ response: String, customerEmail: String?) {
//        guard let message = response.utterances.first else { return }
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            text: response,
            createdAt: Date(),
            senderId: chatbotId,
            senderName: chatbotName,
            receiverId: Auth.auth().currentUser?.email ?? "",
            receiverName: userName
        )
        
        do {
            try db.collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error)")
        }
        
        let assistantUtterance = Utterance(role: "ROLE_ASSISTANT", content: response)
        conversation.append(assistantUtterance) // 멀티턴 대화를 위한 챗봇 응답 추가
    }
}

// 요청 본문 모델
struct APIRequest: Encodable {
    let app_id: String
    let name: String
    let item: [String]
    let param: [Param]
}

struct Param: Encodable {
    let utterances: [Utterance]
    let config: Config
}

struct Utterance: Encodable {
    let role: String
    let content: String
}

struct Config: Encodable {
    let top_p: Double
    let top_k: Int
    let temperature: Double
    let presence_penalty: Double
    let frequency_penalty: Double
    let repetition_penalty: Double
}

// API 응답 모델
//struct APIResponse: Decodable {
//    let response: [MenuItem]
//}

struct MenuItem: Decodable {
    let menu: String
    let quantity: String
}


//// 챗봇으로부터 답장 메시지를 받는 경우임
//newMessage = ChatMessage(
//    text: text,
////                customerEmail: "",      // 이거 유의
//    createdAt: Date(),
//    senderId: chatbotId,
//    senderName: chatbotName,
//    receiverId: customerEmail!,     // 이거 관심
//    receiverName: userName
//)
