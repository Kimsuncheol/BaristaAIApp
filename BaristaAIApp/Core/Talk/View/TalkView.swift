//
//  TalkView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI

struct TalkView: View {
    let user: User?
//    @StateObject private var viewModel = ChatViewModel(customerEmail: user?.email ?? "") // ChatViewModel 인스턴스 생성
    @StateObject private var viewModel: ChatViewModel
    @State private var isInputFocused: Bool = false // 포커스 상태 관리
    
    init(user: User?) {
        self.user = user
        _viewModel = StateObject(wrappedValue: ChatViewModel(customerEmail: user?.email ?? "", userName: user?.username ?? ""))
    }
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        // 최초 생성 메시지일 경우나 각 메시지별로 생성일이 다를 경우 날짜 표시
                        Group {
                            if index == 0 || shouldShowDate(for: message) {
                                Text(message.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 5)
                            }
                            
                            ChatMessageView(user: user, viewModel: viewModel, message: message)
                                .id(message.id)
                            
                        }
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
//                    viewModel.isLoadingResponse = true
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
        .onAppear {
            viewModel.initializeIfNeeded()
        }
    }
    
    // 이전 메시지와 현재 메시지의 시간을 비교하여 날짜 표시 여부 결정
    private func shouldShowDate(for message: ChatMessage) -> Bool {
        guard let index = viewModel.messages.firstIndex(where: { $0.id == message.id }), index > 0 else {
            return true
        }
        let previousMessage = viewModel.messages[index - 1]
        return !Calendar.current.isDate(message.createdAt, inSameDayAs: previousMessage.createdAt)
    }
}

#Preview {
//    TalkView()
    ContentView()
}
