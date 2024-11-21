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
    @Published var menuLexicon: [String: String] = [:] // 동적인 어휘 사전
    @Published var isConnected: Bool = true // Firestore 연결 상태
    @Published var remainingTime: TimeInterval = 0
    private var hasInitialized = false // 초기화 여부 확인
    private var timer: Timer? // 타이머 인스턴스
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration? // Firestore 리스너를 관리하기 위한 변수
    var customerEmail: String
    var userName: String
    var chatbotId: String = "chatbot" // 대화형 엔진의 ID
    let chatbotName: String = "Barista AI" // 대화형 엔진의 이름
    private var conversation: [Utterance] = [] // 대화를 저장하는 배열
    private var cancellables = Set<AnyCancellable>()
    private var connectionListener: ListenerRegistration?

    let collectionName: String = "chatRooms"
    var waitingForResponseTime: Double = 0.0
    
    var greetingLexicon: [String] = [
        "안녕", "안녕하세요", "좋은 아침이에요", "안녕하십니까",
        "좋은 저녁이에요", "좋은 오후에요", "좋은 하루 되세요",
        "굿모닝", "굿애프터눈", "굿이브닝",
        "반갑습니다", "처음 뵙겠습니다", "오랜만이에요", "만나서 반가워요",
        "하이", "헬로", "안뇽", "여보세요",
        "잘 있었어요?", "잘 지냈어?", "오늘 날씨 좋네요",
        "새해 복 많이 받으세요", "메리 크리스마스", "즐거운 명절 되세요",
        "무엇을 도와드릴까요?", "바리스타 AI입니다!", "어서 오세요"
    ]
    
    let placeOrderPatterns: [String] = [
        "잔 줘.", " 잔 줘.", "잔 주세요.", " 잔 주세요.", "잔 주시겠어요?", " 잔 주시겠어요?",
        "1잔 주세요.", "2잔 주세요.", "3잔 주세요.", "한 잔 주세요.", "두 잔 주세요.", "세 잔 주세요.",
        "한 개 주세요.", "두 개 주세요.", "세 개 주세요.", "1컵 주세요.", "2컵 주세요.",
        "주세요.", "하나 주세요.", "둘 주세요.", "셋 주세요.", "한 잔만 주세요.", "두 잔만 주세요.",
        "한 잔 부탁드려요.", "두 잔 부탁드려요.", "세 잔 부탁드려요.", "잔 하나 부탁드려요.", "잔 둘 부탁드려요.",
        "잔 줘 ", " 잔 줘 ", "잔 주세요 ", " 잔 주세요 ", "잔 주시겠어요 ", " 잔 주시겠어요 ",
        "한 잔 가능할까요?", "한 잔 부탁할게요.", "한 잔 주문할게요.", "한 잔 받을 수 있을까요?", "잔 한 개 주세요.",
    ]
    
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
    
    let systemPrompt: String = """
    안녕하세요! 저는 Barista AI입니다. 저는 음료 주문, 메뉴 추천, 또는 일반적인 질문에 도움을 드릴 수 있습니다.
    무엇을 도와드릴까요?
    """
    let disconnectedMessage = "AI Barista와의 대화가 없어 종료되었습니다."
    
    init(customerEmail: String, userName: String) {
        self.customerEmail = customerEmail
        self.userName = userName
    }
    
    deinit {
        stopTimer()
        listenerRegistration?.remove()
        connectionListener?.remove()
    }
    
    func initializeIfNeeded() {
        guard !hasInitialized else { return }
        hasInitialized = true
//        self.customerEmail = customerEmail
//        self.userName = userName
        if !self.customerEmail.isEmpty && !self.userName.isEmpty {
            initializeChat()
            self.setupConnectionListener()
        }
    }
    
    private func initializeChat() {
        receiveInitialzeMessage()
        
        fetchMenuLexicon()
        fetchMessages(customerEmail: customerEmail)
    }
    
    func receiveInitialzeMessage() { // 이거 함수 이름 어떻게 작명해야 해?
        let initialMessage = ChatMessage(
            text: systemPrompt,
            createdAt: Date(),
            senderId: chatbotId,
            senderName: chatbotName,
            receiverId: customerEmail,
            receiverName: userName
        )
        
        // Firestore에 initialMessage 추가
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        // chatRoomRef 타입 확인
        print("chatRoomRef 타입 확인: \(type(of: chatRoomRef))")
        do {
            try chatRoomRef.collection("messages").addDocument(from: initialMessage)
            updateRecentMessage(FIRDocumentReference: chatRoomRef, text: systemPrompt)
        } catch {
            print("Error adding initial message to Firestore: \(error)")
        }
    }
    
    // Firestore에서 메뉴 컬렉션 데이터를 가져와 동적인 어휘 사전 생성
    func fetchMenuLexicon() {
        db.collection("menu").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching menu data: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            // Firestore에서 메뉴 이름 가져오기
            for document in documents {
                if let menuName = document.data()["name"] as? String {
                    self.menuLexicon[menuName] = "음료" // 메뉴 이름을 어휘 사전에 추가
                }
            }
            print("Menu lexicon loaded: \(self.menuLexicon)")
        }
    }
    
    func updateRecentMessage(FIRDocumentReference: DocumentReference, text: String) {
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        chatRoomRef.setData([
        "chatRoomId": chatRoomId,
        "participants": [customerEmail, chatbotId],
        "lastMessage": text,
        "lastUpdate": Timestamp()
        ], merge: true)
    }
    
    func fetchMessages(customerEmail: String) {
        listenerRegistration?.remove()
        
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        
        listenerRegistration = chatRoomRef.collection("messages")
            .whereField("senderId", in: [customerEmail, chatbotId])
            .whereField("receiverId", in: [customerEmail, chatbotId])
            .order(by: "createdAt", descending: false)
//            .limit(to: 50)
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
//                    self.setupConnectionListener()
//                    self.setupListener(customerEmail: customerEmail)
                }
//                self?.isLoadingResponse = false
            }
    }
    
    /// 5분동안 대화가 없을 경우 연결이 끊겼다고 판단
    private func setupConnectionListener() {
        connectionListener?.remove()
        stopTimer()
        
        let chatRoomRef = db.collection(collectionName).document(chatRoomId)
        
        connectionListener = chatRoomRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching chat room: \(error)")
                return
            }
            
            guard let data = documentSnapshot?.data() else { return }
            let lastUpdate = data["lastUpdate"] as? Timestamp ?? Timestamp()
            
            // Firestore의 UTC 시간을 로컬 시간대로 변환
            let lastUpdateDate = lastUpdate.dateValue()
            
            // 타이머 초기화 및 시작
            self.startTimer(lastUpdate: lastUpdateDate)
        }
    }
    
    // 타이머 시작 및 업데이트
    private func startTimer(lastUpdate: Date) {
        stopTimer()
        if timer != nil { return }
        
        let localLastUpdate = convertToLocalTime(lastUpdate)
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let localNow = self.convertToLocalTime(now) // 현재 시간도 로컬 시간대로 변환
            
            let elapsedTime = localNow.timeIntervalSince(localLastUpdate)
            let remainingTime = max(0, 300 - elapsedTime)
            self.remainingTime = remainingTime
            
            print("localNow: \(localNow), lastUpdate: \(localLastUpdate), elapsedTime: \(elapsedTime), remainingTime: \(remainingTime)")

            
            if remainingTime <= 0 {
                stopTimer()
                self.isConnected = false
                print("Disconnected due to timeout.")

                // Firestore 컬렉션에 연결 끊김 메시지 추가
                let disconnectedMessage = ChatMessage(
                    text: self.disconnectedMessage,
                    createdAt: now,
                    senderId: self.chatbotId,
                    senderName: self.chatbotName,
                    receiverId: self.customerEmail,
                    receiverName: self.userName
                )

                let chatRoomRef = self.db.collection(self.collectionName).document(self.chatRoomId)

                do {
                    try chatRoomRef.collection("messages").addDocument(from: disconnectedMessage) { error in
                        if let error = error {
                            print("Error adding disconnected message to Firestore: \(error)")
                        } else {
                            print("Disconnected message added to Firestore.")
                        }
                    }
//                    self.updateRecentMessage(FIRDocumentReference: chatRoomRef, text: self.disconnectedMessage) -> 이게 문제였어 ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ
                } catch {
                    print("Error adding disconnected message to Firestore: \(error)")
                }
                return
            }
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
        
        if self.messages.last?.text == self.disconnectedMessage {
            receiveInitialzeMessage()
        }

        let newMessage = ChatMessage(
            text: text,
            createdAt: Date(),
            senderId: customerEmail,
            senderName: userName,
            receiverId: chatbotId,
            receiverName: chatbotName
        )
        
        do {
            self.isLoadingResponse = true
            try chatRoomRef.collection("messages").addDocument(from: newMessage) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "메시지를 전송하는 중 오류가 발생했습니다."
                        self.isLoadingResponse = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.text = ""
                        self.updateRecentMessage(FIRDocumentReference: chatRoomRef, text: self.text)
//                        self.stopTimer()
                        self.startTimer(lastUpdate: newMessage.createdAt)
                    }
                }
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
//        callChatbotAPItoFindIntent(with: text, conversation: conversation, customerEmail: customerEmail)
        
    
        let intent = detectIntent(text: text)
        switch intent {
        case .order_drink:
            print("주문이 감지되었습니다.")
            callChatbotAPI(with: text, conversation: conversation, customerEmail: customerEmail, model: .order_drink, intent: "order_drink")
        case .intent:
            print("인사가 감지되었습니다.")
            callChatbotAPI(with: text, conversation: conversation, customerEmail: customerEmail, model: .intent, intent: "etc_conversation")
        case .ask_about_menu:
            print("주문이 아닌 대화입니다.")
            callChatbotAPI(with: text, conversation: conversation, customerEmail: customerEmail, model: .ask_about_menu, intent: "ask_about_menu")
        }
    }
    
    // 메시지에서 의도를 파악하는 함수
    func detectIntent(text: String) -> ChatbotModel {
        if isOrderDrink(text: text) {
            return .order_drink
        } else if isSimpleGreeting(text: text) {
            return .intent
        } else {
            return .ask_about_menu
        }
    }
    
    // 메시지가 주문인지 감지하는 함수 (메뉴 사전 어휘 기반)
    func isOrderDrink(text: String) -> Bool {
        let similarityThreshold = 0.6

        // 1. 메뉴 이름과 주문 패턴을 조합하여 비교
        for menuName in menuLexicon.keys {
            for pattern in placeOrderPatterns {
                // 메뉴 이름과 주문 패턴을 조합한 문장 생성
                let combinedText = "\(menuName) \(pattern)"

                // 입력 텍스트와 조합된 문장의 유사도 계산
                let similarity = optimizedNGramCosineSimilarity(text1: text, text2: combinedText, nRange: 1...3)
                
                // 유사도가 임계값 이상일 경우 주문으로 간주
                if similarity >= similarityThreshold {
                    return true
                }
            }
        }
        
        return false
    }
    
    // 메시지가 단순 인사인지 감지하는 함수
    func isSimpleGreeting(text: String) -> Bool {
        let similarityThreshold = 0.5
        for greeting in greetingLexicon {
            let similarity = optimizedNGramCosineSimilarity(text1: text, text2: greeting, nRange: 1...3)
            if similarity >= similarityThreshold {
                return true
            }
        }
        return false
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
        print("handleChatbotResponse - intent: \(intent)")
        // intent에 따라 처리
        
        var responseText: String
        
        if intent == "etc_conversation" {
            do {
                print("handleChatbotResponse - data: \(data)")
                responseText = self.systemPrompt
                
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
        } else if intent == "order_drink" {
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.hasPrefix("[") || responseString.hasPrefix("{") {
                        let apiResponse = try JSONDecoder().decode([APIResponse].self, from: data)
                        if apiResponse.count == 1 {
                            responseText = "\(apiResponse[0].menu) \(apiResponse[0].quantity)잔 주문되었습니다."
                        } else {
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
        } else {
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
                            "participants": [customerEmail ?? "", chatbotId],   //
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
    
    private func convertToLocalTime(_ date: Date) -> Date {
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: date))
        return date.addingTimeInterval(timeZoneOffset)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
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
    func tokenize(includePunctuation: Bool = false) -> [String] {
        var tokens: [String] = []
        
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = self
        
        let range = NSRange(location: 0, length: self.utf16.count)
        let options: NSLinguisticTagger.Options = includePunctuation ? [.omitWhitespace] : [.omitPunctuation, .omitWhitespace, .omitOther]
        tagger.enumerateTags(in: range, scheme: .tokenType, options: options) { tag, tokenRange, _, _ in
//            if let tag = tag, tag == .word {
//                let token = (self as NSString).substring(with: tokenRange)
//                tokens.append(token)
//            }
            if let token = (self as NSString).substring(with: tokenRange) as String? {
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

extension String {
    func nGrams(n: Int) -> [String] {
        guard self.count >= n else { return [] }
        
        let characters = Array(self)
        var nGrams: [String] = []
        
        for i in 0...characters.count - n {
            let nGram = characters[i..<(i + n)].map { String($0) }.joined()
            nGrams.append(nGram)
        }
        
        return nGrams
    }
    
    /// N-gram 기반의 term frequency 계산
    func nGramTermFrequency(n: Int) -> [String: Int] {
        let nGrams = self.nGrams(n: n)
        var frequency: [String: Int] = [:]
        
        for nGram in nGrams {
            frequency[nGram, default: 0] += 1
        }
        
        return frequency
    }
}

extension ChatViewModel {
    /// N-gram 기반의 코사인 유사도 계산
    func nGramCosineSimilarity(text1: String, text2: String, n: Int) -> Double {
        let tf1 = text1.nGramTermFrequency(n: n)
        let tf2 = text2.nGramTermFrequency(n: n)
        
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
    
    /// 최적의 N-gram 크기 찾기 (기본적으로 1~5 사이 탐색)
    func findOptimalN(text1: String, text2: String, range: ClosedRange<Int> = 1...5) -> Int {
        var maxSimilarity = 0.0
        var bestN = 1
        
        for n in range {
            let similarity = nGramCosineSimilarity(text1: text1, text2: text2, n: n)
            if similarity > maxSimilarity {
                maxSimilarity = similarity
                bestN = n
            }
        }
        return bestN
    }

    /// 최적화된 N으로 코사인 유사도 계산
    func optimizedNGramCosineSimilarity(text1: String, text2: String, nRange: ClosedRange<Int> = 1...5) -> Double {
        let optimalN = findOptimalN(text1: text1, text2: text2, range: nRange)
//        print("Optimal N found: \(optimalN)")
        return nGramCosineSimilarity(text1: text1, text2: text2, n: optimalN)
    }
}

enum ChatbotModel {
    case intent
    case order_drink
    case ask_about_menu
}

