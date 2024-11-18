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
    @Published var isLoadingResponse = false // 챗봇 응답 로딩 상태
    @Published var errorMessage: String? = nil // 에러 메시지 표시
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration? // Firestore 리스너를 관리하기 위한 변수
    private let userName = Auth.auth().currentUser?.displayName ?? "User" // 현재 사용자의 이름 -> LoginView 진입할 때 버벅거림의 원인
    var chatbotId: String = "chatbot" // 대화형 엔진의 ID
    let chatbotName: String = "Barista AI" // 대화형 엔진의 이름
    private var conversation: [Utterance] = [] // 대화를 저장하는 배열
    private var cancellables = Set<AnyCancellable>()
    
    let collectionName: String = "chatRooms"
    let collectionName2: String = "\(Auth.auth().currentUser?.email ?? "")/chatbot"
    var waitingForResponseTime: Double = 0.0
    
    private var baristaOrderConformModel: [String: String] = [
        "app_id": "bf8df488-ac09-5c0d-a3b5-400760af4b18", 
        "name": "maal_barista_sejong-capstone_stream",
        "item": "mxCell#13"
    ]
    
    private var baristaIntentModel: [String: String] = [
        "app_id": "0f979637-2d92-5664-bd26-a0a90fc4cec8",
        "name": "maal_intent_sejong-capstone_stream",
        "item": "mxCell#13"
    ]
    
    private var maumGPTStreamModel: [String: String] = [
        "app_id": "77e64f9d-a586-5ec4-8b6e-b88a91d56a93",
        "name": "sejong_70b_stream",
        "item": "maumgpt-maal2-70b-streamchat"
    ]
    
    private var chatRoomId: String {
        guard let userEmail = Auth.auth().currentUser?.email else { return "" }
        return "\(userEmail)_\(chatbotId)"
    }
    
    let orderDrinkPatterns: [String] = [    // 여기에 menu 컬렉션에 있는 음료 이름을 넣어야 함
        "커피 하나 주세요",
        "라떼 주문할게요",
        "아메리카노 하나 부탁해요",
        "카푸치노 주문할래요",
        "카페모카 하나 주세요",
        "모카 주문할게요",
        "에스프레소 하나 주세요",
        "블랙 커피 주문할게요",
        "핫초코 하나 부탁해요",
        "콜드 브루 주문할래요",
        "프라푸치노 하나 주세요",
        "라떼 하나 주문할게요",
        
        "커피 하나 줘",
        "라떼 주문할게",
        "아메리카노 하나 줘",
        "카푸치노 주문할래",
        "카페모카 하나 줘",
        "모카 주문할게",
        "에스프레소 하나 줘",
        "블랙 커피 주문할래",
        "핫초코 하나 줘",
        "콜드 브루 주문할래",
        "프라푸치노 하나 줘",
        "라떼 하나 주문할게"
    ]
    
    init() {
        print("customerEmail : \(Auth.auth().currentUser?.email ?? "from chatViewModel - no user")")    // 이 부분 유의해야
        if let customerEmail = Auth.auth().currentUser?.email {     // 이부분도 유의
            fetchMessages(customerEmail: customerEmail)
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchMessages(customerEmail: String) {
        listenerRegistration?.remove()
        
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        
        listenerRegistration = chatRoomRef.collection("messages")
            .whereField("senderId", in: [customerEmail, chatbotId])
            .whereField("receiverId", in: [customerEmail, chatbotId])
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
//                self?.messages = querySnapshot?.documents.compactMap { document in
//                    try? document.data(as: ChatMessage.self)
//                } ?? []
                // 기존 메시지를 배열에 추가
                let fetchedMessages = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: ChatMessage.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self.messages = fetchedMessages
                    self.setupListener(customerEmail: customerEmail)
                }
//                self?.isLoadingResponse = false
            }
    }
    
    /// 실시간 리스너 설정
    func setupListener(customerEmail: String) {
        listenerRegistration?.remove()
        
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        
        listenerRegistration = chatRoomRef.collection("messages")
            .whereField("senderId", in: [customerEmail, chatbotId])
            .whereField("receiverId", in: [customerEmail, chatbotId])
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                guard let changes = querySnapshot?.documentChanges else { return }
                
                DispatchQueue.main.async {
                    for change in changes {
                        if change.type == .added {
                            if let newMessage = try? change.document.data(as: ChatMessage.self) {
                                if !self.messages.contains(where: { $0.id == newMessage.id }) {
                                    self.messages.append(newMessage)
                                }
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                                    self.isLoadingResponse = false
//                                }
                            }
                        }
                    }
                }
            }
    }
    
    
    // Firestore에 메시지 전송
    func sendMessage(customerEmail: String?) {
        guard let customerEmail = customerEmail, !text.isEmpty else { return }
//        self.isLoadingResponse = true

        let chatRoomRef = db.collection(collectionName).document(chatRoomId)

        // 아랫 부분 100% 오류 발생할 거임. 지금은 탐지를 못하는 중이지만, 모든 customer에게 같은 메시지를 전송하게 될 거라서
        // customerEmail 속성을 없애고 senderId에 customerEmail 넣었으니 아마 오류 해결되었을 듯
        let newMessage = ChatMessage(
            text: text,
            createdAt: Date(),
            senderId: customerEmail,
            senderName: userName,
            receiverId: chatbotId,
            receiverName: chatbotName
        )
        
        chatRoomRef.setData([
            "chatRoomId": chatRoomId,
            "participants": [customerEmail, chatbotId],
            "lastMessage": text,
            "lastUpdate": Timestamp()
        ], merge: true)
        
        do {
            self.isLoadingResponse = true
            print("isLoadingResponse : \(self.isLoadingResponse)")
//            _ = try db.collection(collectionName).addDocument(from: newMessage)
            _ = try chatRoomRef.collection("messages").addDocument(from: newMessage)
            DispatchQueue.main.async {
                self.text = ""   // To reset after transmit a message
//                self.isLoadingResponse = true
            }
        } catch {
            print("Error sending message: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "메시지를 전송하는 중 오류가 발생했습니다."
                self.isLoadingResponse = false
            }
            return
        }
        
        let userUtterance = Utterance(role: "ROLE_USER", content: text) // 사용자 메시지
        conversation.append(userUtterance)
        
        // 의도를 먼저 파악해야 하기 때문
//        callChatbotAPI(with: text, conversation: conversation, customerEmail: customerEmail, model: .intent)
        callChatbotAPItoFindIntent(with: text, conversation: conversation, customerEmail: customerEmail)
    }
    
    // 의도를 먼저 파악하고, 의도에 따라 API 호출 또 해야 함.
    private func callChatbotAPItoFindIntent(with message: String, conversation: [Utterance], customerEmail: String?) {
        let start = Date()
        
        guard let url = URL(string: "https://norchestra.maum.ai/harmonize/dosmart") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let requestBody = APIRequest(
            app_id: baristaIntentModel["app_id"] ?? "",
            name: baristaIntentModel["name"] ?? "",
            item: baristaIntentModel["item"]?.components(separatedBy: ",") ?? [],
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
        } catch  {
            print("callChatbotAPItoFindIntent - Error encoding request body: \(error)")
            return
        }
        
        // API 호출 결과에 따라 다음 API 호출을 수행
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                return response.data
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("callChatbotAPItoFindIntent - Error calling API: \(error)")
                    self.isLoadingResponse = false
                    let end = Date()
                    self.waitingForResponseTime = end.timeIntervalSince(start)
                }
            }, receiveValue: { [weak self] data in
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.contains("[\"order_drink\"]") || responseString.contains("[\'order_drink\']") {     // 반환결과 order_drink가 포함되어 있으면
                        self?.callChatbotAPI(with: message, conversation: conversation, customerEmail: customerEmail, model: .order_drink, intent: responseString)
                    } else if responseString.contains("[\"ask_about_menu\"]") || responseString.contains("[\'ask_about_menu\']") {   // 반환결과 ask_about_menu가 포함되어 있으면
                        self?.callChatbotAPI(with: message, conversation: conversation, customerEmail: customerEmail, model: .ask_about_menu, intent: responseString)
                    } else {        // 그 외의 경우(인사를 한다거나)
                        self?.handleChatbotResponse(data: data, customerEmail: customerEmail, intent: responseString)
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    private func callChatbotAPI(with message: String, conversation: [Utterance], customerEmail: String?, model: ChatbotModel, intent: String) {
//        self.isLoadingResponse = true
        let start = Date()
        
        // 챗봇 API 호출
        guard let url = URL(string: "https://norchestra.maum.ai/harmonize/dosmart") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // 선택한 모델에 따라 app_id, name 설정
        let selectedModel: [String: String]
        switch model {
        case .order_drink:
            selectedModel = baristaOrderConformModel
        case .ask_about_menu:
            selectedModel = maumGPTStreamModel
        default:
            selectedModel = baristaIntentModel
        }
        
        print("selectedModel: \(selectedModel)")
        
        // 멀티턴 대화를 위한 utterances 배열
        let requestBody = APIRequest(
            app_id: selectedModel["app_id"] ?? "",
            name: selectedModel["name"] ?? "",
            item: selectedModel["item"]?.components(separatedBy: ",") ?? [],
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
            print("callChatbotAPI - Error encoding request body: \(error)")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                if let string = String(data: response.data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        print("API 응답: \(string)") // 응답 내용 출력
                        let end = Date()
                        self.waitingForResponseTime = end.timeIntervalSince(start)
                    }
                }
                
                return response.data
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("callChatbotAPI - Error calling API: \(error)")
                    self.isLoadingResponse = false
                    let end = Date()
                    self.waitingForResponseTime = end.timeIntervalSince(start)
                }
            }, receiveValue: { [weak self] data in
                if let responseString = String(data: data, encoding: .utf8) {
                    print("callChatbotAPI - responseString: \(responseString)")
                    self?.handleChatbotResponse(data: data, customerEmail: customerEmail, intent: intent)
                }
            })
            .store(in: &cancellables)
    }
    
    private func handleChatbotResponse(data: Data, customerEmail: String?, intent: String) {
//        guard let message = response.utterances.first else { return }
        print("handleChatbotResponse - intent: \(intent.description)")
        // intent에 따라 처리
        
        var responseText: String
        
        if intent.contains("[\"etc_conversation\"]") || intent.contains("[\'etc_conversation\']") {
            do {
                print("handleChatbotResponse - data: \(data)")
                responseText = "안녕하세요. 무엇을 도와드릴까요?"
                
                let newMessage = ChatMessage(
                    text: responseText,
                    createdAt: Date(),
                    senderId: chatbotId,
                    senderName: chatbotName,
                    receiverId: customerEmail ?? "",        //
                    receiverName: userName
                )
                
                let chatRoomRef = db.collection(collectionName).document(chatRoomId)
                
                try chatRoomRef.setData([
                    "chatRoomId": chatRoomId,
                    "participants": [customerEmail ?? "", chatbotId],
                    "lastMessage": responseText,
                    "lastUpdate": Timestamp()
                ], merge: true)
                
                try chatRoomRef.collection("messages").addDocument(from: newMessage)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + self.waitingForResponseTime) {
                    self.isLoadingResponse = false
                }
                
                let chatbotUtterance = Utterance(role: "ROLE_ASSISTANT", content: responseText)
                conversation.append(chatbotUtterance)
            } catch {
                print("handleChatbotResponse - Error decoding API response: \(error)")
            }
        } else if intent.contains("[\"order_drink\"]") || intent.contains("[\'order_drink\']") {
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.hasPrefix("[") || responseString.hasPrefix("{") {
                        let apiResponse = try JSONDecoder().decode([APIResponse].self, from: data)
                        if apiResponse.count == 1 {
                            responseText = "\(apiResponse[0].menu) \(apiResponse[0].quantity)잔 주문되었습니다."
                        } else {
                            // apiResponse에 있는 음료수 목록을 출력
                            var menuList: String = ""
                            for i in 0..<apiResponse.count {
                                menuList += "\(apiResponse[i].menu) \(apiResponse[i].quantity)잔\n"
                            }
                            responseText = "\(menuList) 주문되었습니다."
                        }
                        
                        let newMessage = ChatMessage(
                            text: responseText,
                            createdAt: Date(),
                            senderId: chatbotId,
                            senderName: chatbotName,
                            receiverId: customerEmail ?? "",
                            receiverName: userName
                        )
                        
                        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
                        
                        try chatRoomRef.setData([
                            "chatRoomId": chatRoomId,
                            "participants": [customerEmail ?? "", chatbotId],
                            "lastMessage": responseText,
                            "lastUpdate": Timestamp()
                        ], merge: true)
                        
                        try chatRoomRef.collection("messages").addDocument(from: newMessage)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.waitingForResponseTime) {
                            self.isLoadingResponse = false
                        }
                        
                        let chatbotUtterance = Utterance(role: "ROLE_ASSISTANT", content: responseText)
                        conversation.append(chatbotUtterance)
                    }
                }
                
            } catch {
                print("----- handleChatbotResponse - Error decoding API response: \(error)")
            }
        } else if intent.contains("[\"ask_about_menu\"]") || intent.contains("[\'ask_about_menu\']") {
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    do {
                        // responseString을 디코딩
                        print("responseString: \(responseString)")
                        responseText = responseString
                        
                        let newMessage = ChatMessage(
                            text: responseText,
                            createdAt: Date(),
                            senderId: chatbotId,
                            senderName: chatbotName,
                            receiverId: customerEmail ?? "",        //
                            receiverName: userName
                        )
                        
                        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
                        
                        try chatRoomRef.setData([
                            "chatRoomId": chatRoomId,
                            "participants": [customerEmail ?? "", chatbotId],
                            "lastMessage": responseText,
                            "lastUpdate": Timestamp()
                        ], merge: true)
                        
                        try chatRoomRef.collection("messages").addDocument(from: newMessage)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.waitingForResponseTime) {
                            self.isLoadingResponse = false
                        }
                        
                        let chatbotUtterance = Utterance(role: "ROLE_ASSISTANT", content: responseText)
                        conversation.append(chatbotUtterance)
                    } catch {
                        print("handleChatbotResponse - Error decoding API response: \(error)")
                    }
                }
            } catch {
               print("----- handleChatbotResponse - Error decoding API response: \(error)")
           }
        }
    }
    /// 사용자의 메시지가 인사인지 감지하는 함수
    func isOrderDrink(text: String) -> Bool {
        for pattern in orderDrinkPatterns {
            let similarity = cosineSimilarity(text1: text, text2: pattern)
            if similarity >= 0.5 { // 유사도 기준을 설정 (예: 0.5 이상)
                return true
            }
        }
        return false
    }
    
    /// 코사인 유사도 계산 함수
    func cosineSimilarity(text1: String, text2: String) -> Double {
        let tf1 = text1.termFrequency()
        let tf2 = text2.termFrequency()
        
        // 모든 단어 집합
        let allKeys = Set(tf1.keys).union(tf2.keys)
        
        // 벡터 생성
        let vector1 = allKeys.map { Double(tf1[$0] ?? 0) }
        let vector2 = allKeys.map { Double(tf2[$0] ?? 0) }
        
        // 벡터 내적 계산
        let dotProduct = zip(vector1, vector2).reduce(0.0) { $0 + ($1.0 * $1.1) }
        
        // 벡터의 크기 계산
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        
        // 코사인 유사도 계산
        if magnitude1 == 0 || magnitude2 == 0 {
            return 0.0
        } else {
            return dotProduct / (magnitude1 * magnitude2)
        }
    }
}


// 요청 본문 모델
struct APIRequest: Encodable {
    let app_id: String
    let name: String
    let item: [String]
    let param: [Param]
}

struct APIResponse: Decodable {
//    let menu: [MenuItem]
    let menu: String
    let quantity: String
}
//struct APIResponse: Decodable {
//    let intent: String
//}

struct APIResponseForEtcAsk: Decodable {
    let string: String
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

extension String {
    // 한국어 및 영어 텍스트를 형태소 단위로 토큰화하는 함수
    func tokenize() -> [String] {
        var tokens: [String] = []
        
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = self
        
        let range = NSRange(location: 0, length: self.utf16.count)
        tagger.enumerateTags(in: range, scheme: .tokenType, options: [.omitPunctuation, .omitWhitespace, .omitOther]) { tag, tokenRange, _, _ in
            if let tag = tag, tag == .word {
                let token = (self as NSString).substring(with: tokenRange)
                tokens.append(token)
            }
        }
        
        return tokens
    }
    
    func termFrequency() -> [String: Int] {
        let tokens = tokenize()
        var frequency: [String: Int] = [:]
        
        for token in tokens {
            frequency[token, default: 0] += 1
        }
        
        return frequency
    }
}

enum ChatbotModel {
    case intent
    case order_drink
    case ask_about_menu
}

