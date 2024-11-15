//
//  TalkView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI
import Speech

struct TalkView: View {
    let user: User?
    @StateObject private var viewModel = ChatViewModel() // ChatViewModel 인스턴스 생성
    @StateObject private var keyboardResponder = KeyboardResponder() // 키보드 높이 감지 객체
    @State private var isInputFocused: Bool = false // 포커스 상태 관리
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(0..<viewModel.messages.count, id: \.self) { index in
                        let message = viewModel.messages[index]
                        let showTime = shouldShowTime(for: index) // 이전 메시지와 비교하여 시간 표시 여부 결정
                        
                        HStack {
                            // 각 메시지별로 생성일이 다를 경우 날짜 표시
                            if showTime {
//                                // 최초 메시지 생성일 표시하고, 이전 메시지와 현재 메시지와 생성일이 다를 경우 표시
                                if index == 0 || !Calendar.current.isDate(viewModel.messages[index].createdAt, inSameDayAs: viewModel.messages[index - 1].createdAt) {
                                    
                                    Text(viewModel.messages[index].createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 5)
                                    
                                }
                            }
                        }
                        
                        ChatMessageView(user: user, index: index, message: message, showTime: showTime)
                    }
                }
                .rotationEffect(Angle(degrees: 180))
                .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
            }
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
            
            Spacer()
            
            InputTextView(text: $viewModel.text, isFocused: $isInputFocused, onSend: { _ in
                if !viewModel.text.isEmpty {
                    viewModel.sendMessage(customerEmail: user?.email) // ViewModel의 sendMessage 호출
                }
            })
            
        }
        .padding(.top, 1)
        .padding(.bottom)
        .frame(width: UIScreen.main.bounds.width - 20)
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    // 이전 메시지와 현재 메시지의 시간을 비교하여 표시 여부 결정
    func shouldShowTime(for index: Int) -> Bool {
        guard index > 0 else { return true }
        
        let currentMessage = viewModel.messages[index]
        let previousMessage = viewModel.messages[index - 1]
        
        let timeInterval = currentMessage.createdAt.timeIntervalSince(previousMessage.createdAt) / 60
        
        return timeInterval >= 1
    }
}

#Preview {
    ContentView()
//    TalkView()
}
