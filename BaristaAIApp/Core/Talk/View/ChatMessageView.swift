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
                
                HStack(alignment: .bottom) {
                    // 보낸 시간 표시 (조건에 따라)
//                    if showTime {
//                    }
                    Text(message.formattedTime())
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(message.text)
                        .padding(10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            } else {
                // 대화형 엔진이 보낸 메시지
                Image("bot")
                    .resizable()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading) {
                    Text(viewModel.chatbotName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if viewModel.isLoadingResponse {
                        TypingAnimationView()
                    }  else {
                        HStack(alignment: .bottom) {
                            Text(message.text)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            
                            Text(message.formattedTime())
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.top, index == 0 ? 9 : 0)
        .padding(.bottom, index == 0 ? 5 : 0)
        .padding(.vertical, index > 0 && index < viewModel.messages.count - 1 ? 5 : 0)
        .padding(.top, viewModel.messages.count - 1 == index ? 5 : 0)
        .id(index)
    }
}

#Preview {
    ContentView()
}

// 로딩 애니메이션용 TypingAnimationView
struct TypingAnimationView: View {
    @State private var dotCount = 1
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<dotCount, id: \.self) { _ in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
//            withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
//                dotCount = dotCount % 3 + 1
//            }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation {
                    dotCount = dotCount % 3 + 1
                }
            }
        }
    }
}
