//
//  TalkView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI

struct TalkView: View {
    let user: User?
    @StateObject private var viewModel = ChatViewModel() // ChatViewModel 인스턴스 생성
    @State private var isInputFocused: Bool = false // 포커스 상태 관리
    @State private var isFetching = false // 추가 메시지 로드 상태 관리
    
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

//import SwiftUI
//import Speech
//
//struct TalkView: View {
//    let user: User?
//    @StateObject private var viewModel = ChatViewModel() // ChatViewModel 인스턴스 생성
//    @State private var isInputFocused: Bool = false // 포커스 상태 관리
//    @State private var isFetching = false // 추가 메시지 로드 상태 관리
//
//    
//    var body: some View {
//        VStack {
////            ScrollViewReader { proxy in
////                
////            }
//            ScrollView(showsIndicators: false) {
//                LazyVStack {
//                    ForEach(viewModel.messages) { message in
//                        // 최초 생성 메시지일 경우나 각 메시지별로 생성일이 다를 경우 날짜 표시
//                        Group {
//                            if viewModel.messages.firstIndex(where: { $0.id == message.id }) == 0 || shouldShowDate(for: message) {
//                                Text(message.createdAt, style: .date)
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                    .padding(.vertical, 5)
//                            }
//                            
//                            ChatMessageView(user: user, viewModel: viewModel, message: message)
//                                .id(message.id)
//                            
//                        }
//                    }
//                    
//                    // 로딩 인디케이터
//                    if viewModel.isLoadingOlderMessages || viewModel.isLoadingNewerMessages {
//                        ProgressView()
//                            .padding()
//                    }
//
//                    // 하단 패딩 추가
//                    Spacer().frame(height: 20)
//                }
//                .rotationEffect(Angle(degrees: 180))
//                .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
//            }
//            .coordinateSpace(name: "scrollView")
//            .rotationEffect(Angle(degrees: 180))
//            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
//            .padding(.bottom, 1)
//            .onAppear {
//                if let lastMessage = viewModel.messages.last {
//                    viewModel.fetchNewerMessages(customerEmail: user?.email, lastMessage: lastMessage)
//                }
//            }
//            
//            Spacer()
//            
//            InputTextView(text: $viewModel.text, isFocused: $isInputFocused, onSend: { _ in
//                if !viewModel.text.isEmpty {
//                    viewModel.sendMessage(customerEmail: user?.email) // ViewModel의 sendMessage 호출
//                }
//            })
//        }
//        .padding(.top, 1)
//        .padding(.bottom)
//        .frame(width: UIScreen.main.bounds.width - 20)
//        .onTapGesture {
//            isInputFocused = false
//        }
//        .onAppear {
//            if let customerEmail = user?.email {
//                viewModel.fetchInitialMessages(customerEmail: customerEmail)
//            }
//        }
//    }
//    
//    
//    // 스크롤 위치에 따라 데이터 로드 처리
//       private func handleScrollFetch(for index: Int) {
//           let topThreshold = 10 // 상단 데이터 로드 트리거 인덱스
//           let bottomThreshold = viewModel.messages.count - 10 // 하단 데이터 로드 트리거 인덱스
//
//           // 상단 페이징
//           if index == topThreshold && !viewModel.isLoadingOlderMessages {
//               isFetching = true
//               DispatchQueue.global().async {
//                   if let customerEmail = user?.email {
//                       viewModel.fetchOlderMessages(customerEmail: customerEmail)
//                   }
//                   DispatchQueue.main.async {
//                       isFetching = false
//                   }
//               }
//           }
//
//           // 하단 페이징
//           if index == bottomThreshold && !viewModel.isLoadingNewerMessages {
//               isFetching = true
//               DispatchQueue.global().async {
//                   if let customerEmail = user?.email {
//                       viewModel.fetchNewerMessages(customerEmail: customerEmail)
//                   }
//                   DispatchQueue.main.async {
//                       isFetching = false
//                   }
//               }
//           }
//       }
//    
//    // 이전 메시지와 현재 메시지의 시간을 비교하여 표시 여부 결정
//    private func shouldShowDate(for message: ChatMessage) -> Bool {
//        guard let index = viewModel.messages.firstIndex(where: { $0.id == message.id }), index > 0 else { return true }
//        let previousMessage = viewModel.messages[index - 1]
//        return !Calendar.current.isDate(message.createdAt, inSameDayAs: previousMessage.createdAt)
//    }
//}
//
//#Preview {
//    ContentView()
////    TalkView()
//}
//
//
