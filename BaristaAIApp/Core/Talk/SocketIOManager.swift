//
//  SocketIOManager.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/5/24.
//


import SocketIO
import FirebaseCore

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    
    @Published var messages: [ChatMessage] = [] // 메시지 목록
    
    init() {
        // 서버 URL을 실제 서버 주소로 변경하세요.
        manager = SocketManager(socketURL: URL(string: "http://192.168.1.5:3000")!, config: [.log(true), .compress])
        socket = manager.defaultSocket
        
        addHandlers()
        socket.connect()
    }
    
    private func addHandlers() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
        }
        
        socket.on(clientEvent: .error) { data, ack in
            print("Socket error: \(data)")
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
        }
        
        socket.on("message") { dataArray, _ in
            if let data = dataArray[0] as? [String: Any],
               let text = data["text"] as? String,
               let senderId = data["senderId"] as? String,
               let senderName = data["senderName"] as? String,
               let receiverId = data["receiverId"] as? String,
               let receiverName = data["receiverName"] as? String,
               let timestamp = data["timestamp"] as? Timestamp {
                
                let message = ChatMessage(
                    id: UUID().uuidString,
                    text: text,
                    createdAt: timestamp.dateValue(),
                    senderId: senderId,
                    senderName: senderName,
                    receiverId: receiverId,
                    receiverName: receiverName
                )
                
                DispatchQueue.main.async {
                    self.messages.append(message)
                }
            }
        }
    }
    
    // 서버로 메시지 전송
    func sendMessage(_ message: String, senderId: String, senderName: String, receiverId: String, receiverName: String) {
        if socket.status == .connected {
            let messageData: [String: Any] = [
                "text": message,
                "senderId": senderId,
                "senderName": senderName,
                "receiverId": receiverId,
                "receiverName": receiverName,
                "timestamp": Timestamp(date: Date())
            ]
            socket.emit("message", messageData)
        } else {
            print("Socket not connected. Message not sent.")
        }
    }
}
