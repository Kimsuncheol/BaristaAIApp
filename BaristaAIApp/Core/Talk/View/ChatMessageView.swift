//
//  ChatMessageView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/6/24.
//

import SwiftUI

struct ChatMessageView: View {
    let user: User?
    @StateObject private var viewModel = ChatViewModel() // ChatViewModel 인스턴스 생성
    let index: Int
    let message: ChatMessage
    let showTime: Bool
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 10) {
            if message.senderId == user?.email {
                // 현재 사용자가 보낸 메시지
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(message.text)
                        .padding(10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    // 보낸 시간 표시 (조건에 따라)
                    if showTime {
                        Text(message.formattedTime())
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                // 대화형 엔진이 보낸 메시지
                Image(systemName: "robotic.vacuum")
                    .resizable()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading) {
                    Text(viewModel.chatbotName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(message.text)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
//        .id(index)
    }
}

#Preview {
    ContentView()
}
